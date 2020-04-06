package covid19;
import flash.Lib;
import flash.display.Sprite;
import flash.display.Shape;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.ui.Keyboard;
import flash.display.Graphics;
import flash.Vector;
import htmlHelper.tools.DivertTrace;
import htmlHelper.tools.TextLoader;
import htmlHelper.tools.CSV;
import htmlHelper.tools.AnimateTimer;
import haxe.ds.StringMap;
import covid19.datas.StatsC19;
import covid19.datas.LongLatAreas;
import covid19.datas.LongLatAreasArr;
import covid19.datas.Area9;
import covid19.datas.Area9Arr;
import covid19.datas.StatsC19Arr;
import covid19.datas.AddLatLong;
import covid19.datas.AddLatLongArr;
import covid19.datas.City;
import covid19.datas.CityArr;
import covid19.datas.DayCounter;
import covid19.datas.PlotPlace;
//import latLongUK.LatLongUK;
import latLongUK.EastNorth;
import covid19.visual.UKcanvasPlot;
import datetime.DateTime;
import htmlHelper.tools.DivertTrace;
import htmlHelper.canvas.CanvasWrapper;
import htmlHelper.canvas.Surface;
import pallette.ColorWheel24;
import uk.CanvasUK;
import latLongUK.LatLongUK;
import js.Browser;
import js.html.CanvasElement;
import covid19.manager.DataManager;
import haxe.ui.Toolkit;
import haxe.ui.components.Button;
import haxe.ui.containers.VBox;
import haxe.ui.core.Screen;
import haxe.ui.components.Calendar;
import haxe.ui.components.DropDown;
class Covid19ofl extends Sprite{ 
    var g:                  Graphics;
    var viewSprite:         Sprite;
    var scale:              Float;
    var leftDown:           Bool = false;
    var rightDown:          Bool = false;
    var downDown:           Bool = false;
    var upDown:             Bool = false;
    var dataManager:    DataManager;
    var canvasWrapper:  CanvasWrapper;
    var surface:        Surface;
    var surface2:       Surface;
    var divertTrace:    DivertTrace;
    var mapPlot:        UKcanvasPlot;
    public static function main(): Void { Lib.current.addChild( new Covid19ofl() ); }
    public function new(){
        super();
        divertTrace = new DivertTrace();
        trace('test');
        var current = Lib.current;
        var stage = current.stage;
        viewSprite = new Sprite();
        g = viewSprite.graphics;
        addChild( viewSprite );
        var squareSize = 100;
        var square = new Shape ();
        square.graphics.beginFill (0xFF0000, 0.5);
        square.graphics.drawRect (0, 0, squareSize, squareSize);
        square.graphics.beginFill (0x00FF00, 0.5);
        square.graphics.drawRect (200, 0, squareSize, squareSize);
        square.graphics.beginFill (0x0000FF, 0.5);
        square.graphics.drawRect (400, 0, squareSize, squareSize);
        square.graphics.endFill ();
        this.addChild (square);
        scale = 1.;
        stage.addEventListener( KeyboardEvent.KEY_DOWN, keyDown );
        stage.addEventListener( KeyboardEvent.KEY_DOWN, keyUp );
        stage.addEventListener( Event.ENTER_FRAME, enterFrame );
        canvasSetup();
        vectorUK();
        mapPlot = new UKcanvasPlot( surface );
        dataManager = new DataManager( finished );
        Toolkit.init();
        var main = new VBox();

        var calendarDD = new DropDown();
        calendarDD.text = "SelectDate";
        calendarDD.type = "date";
        main.addComponent(calendarDD);
        
        var button1 = new Button();
        button1.text = "Button 1";
        main.addComponent(button1);

        var button2 = new Button();
        button2.text = "Button 2";
        main.addComponent(button2);
        this.addChild(main);
        //Screen.instance.addComponent(main);
    }
    function canvasSetup(){
        var canvas = new CanvasWrapper();
        canvas.width  = 1024;
        canvas.height = 768;
        Browser.document.body.appendChild( cast canvas );
        var dom = cast canvas;
        dom.style.setProperty("pointer-events","none");
        surface = new Surface({ x: 10, y: 10, me: canvas.getContext2d() });
    }
    var canvas2: CanvasWrapper;
    function vectorUK(){
        // likely fairly approximate
        canvas2 = new CanvasWrapper();
        canvas2.width  = 1024;
        canvas2.height = 768;
        surface2 = new Surface({ x: 10, y: 10, me: canvas2.getContext2d() });
        var uk = new CanvasUK( surface2 );
        uk.dx = 28;
        uk.dy = 47;
        uk.alpha = 0.8;
        uk.scaleY = 0.975;
        uk.scaleX = 1.04;
        uk.draw();
        var mapPlot2 = new UKcanvasPlot( surface2 );
        mapPlot2.plotGrid();
    }
    public function finished(){
        trace('Animating UK data');
        var tot = dataManager.getMaxTotal();
        trace('tot ' + tot );
        scaleSize = 30/tot;
        mapPlot.sizeScale = scaleSize;//( 1/(1.8 * 10) );
        mapPlot.colorChange = 24/tot;
        trace( dataManager.getUnfound() );
        AnimateTimer.create();
        AnimateTimer.onFrame = render;
    }
    var scaleSize = 0.;
    var count           = 0;
    var framesDivisor   = 8;
    var dayNo = 0;
    public function render(i: Int ):Void{
        count++;
        if( count%framesDivisor == 0 ){
            count = 0;
            renderDate();
        }
    }
    var unplotted:  String = 'unplotted<br>';
    var lastStr:    String = '';
    var currentStr: String = '';
    var str = '';
    @:access( htmlHelper.tools.DivertTrace )
    function renderDate(){
        if( dataManager.getNoDays() > dayNo  ){
            if( dataManager.getDay( dayNo ).length > 100 ){ // don't clear if it's just wales added
                mapPlot.clear();
                var canvasElement: CanvasElement = canvas2;
                surface.me.drawImage( canvasElement, 0, 0, 1024, 768 );
            }
        } 
        lastStr = currentStr + lastStr;
        str = '';
        var colors = ColorWheel24.getWheel();
        var dayStat = dataManager.getDay( dayNo++ );
        for( i in 0...dayStat.length ){
            var stat = dayStat[ i ];
            mapPlot.plot( stat.eastNorth, stat.total, colors );
            str += '<b>' + stat.total + '</b>' 
                + ' ill, ' + ( new DayCounter( stat.date ) ).pretty() + ', ' 
                + stat.place + ' ' + stat.eastNorth.pretty();
            str += '<br>';
        }
        currentStr = str;
        if( dataManager.getNoDays() < dayNo ){
            traceEndData(); // collate traces it's much faster!
            AnimateTimer.onFrame = function(i: Int ){};
        }
    }
    @:access( htmlHelper.tools.DivertTrace )
    function traceEndData(){
        trace('end data');
        divertTrace.traceString = '';
        trace( 'not plotted (' + dataManager.getUnfound() + ')<br>' 
              + 'sizeScale = ' + Math.round((scaleSize/2)*1000)/1000 + 'pixel radius per person' 
              + '<br>-locations plotted are centre of area health services<br>' 
              + currentStr + lastStr );
    }
    inline
    function datePretty( date: DateTime ): String {
        return DayCounter.datePretty( date );
    }
    inline
    function enterFrame( evt: Event ) {
        //update();
        
    }
    inline
    function keyDown( event: KeyboardEvent ): Void {
        var keyCode = event.keyCode;
        if (keyCode == 27) { // ESC
            #if flash
                flash.system.System.exit(1);
            #elseif sys
                Sys.exit(1);
            #end
        }
        switch( keyCode ){
            case Keyboard.LEFT:
                leftDown    = true;
            case Keyboard.RIGHT:
                rightDown   = true;
            case Keyboard.UP:
                upDown      = true;
            case Keyboard.DOWN:
                downDown    = true;
            default: 
        }
        update(); // not sure if this ideal?
    }
    inline
    function keyUp( event: KeyboardEvent ): Void {
        var keyCode = event.keyCode;
        switch(keyCode){
            case Keyboard.LEFT:
                leftDown    = false;
            case Keyboard.RIGHT:
                rightDown   = false;
            case Keyboard.UP:
                upDown      = false;
            case Keyboard.DOWN:
                downDown    = false;
            default: 
        }
    }
    inline
    function update(): Void {
        if( upDown ){
            
        } else if( downDown ){
            
        }
        if( leftDown ) {
            
        } else if( rightDown ) {
            
        }
        leftDown    = false;
        rightDown   = false;
        downDown    = false;
        upDown      = false;
    }
    /*
    inline 
    function renderTriangles(){
        var tri: Triangle;
        var triangles = Triangle.triangles;
        var s = 300;
        var ox = 400;//35;//200;
        var oy = 20;
        g.clear();
        for( i in 0...triangles.length ){
            tri = triangles[ i ];
            #if openfl 
            g.lineStyle( 0, 0xFF0000, 0 );
            #end
            g.moveTo( ox + tri.ax * s, oy + tri.ay * s );
            g.beginFill( gameColors[ tri.colorID ] );
            g.lineTo( ox + tri.ax * s, oy + tri.ay * s );
            g.lineTo( ox + tri.bx * s, oy + tri.by * s );
            g.lineTo( ox + tri.cx * s, oy + tri.cy * s );
            g.endFill();
        }
    }
    */
    inline
    function resize( e: Event ){
        var s = Lib.current.stage;
        var scale =  Math.min( s.stageWidth, s.stageHeight )/2.5;
        var view = viewSprite;
        view.scaleX = view.scaleY = scale;
        view.x = s.stageWidth/2 - view.width/1.9;
        view.y = scale * 0.005;
    }
}