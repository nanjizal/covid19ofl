package covid19.datas;

@:structInit
class InternalLongLatAreas {
    public var admin_area: String;
    public var county:     String;
    public var latitude:   Float;
    public var longitude:  Float;
    public var postcodes:  Int;
    public var active_postcodes: Int;
    public var population:       Int;
    public var households:       Int;
    function new( admin_area:       String
                , county:           String
                , latitude:         Float
                , longitude:        Float
                , postcodes:        Int
                , active_postcodes: Int 
                , population:       Int
                , households:       Int ){
        this.admin_area         = admin_area;
        this.county             = county;
        this.latitude           = latitude;
        this.longitude          = longitude;
        this.postcodes          = postcodes;
        this.active_postcodes   = active_postcodes;
        this.population         = population;
        this.households         = households;
    }
}
@:forward
abstract LongLatAreas( InternalLongLatAreas ) from InternalLongLatAreas to InternalLongLatAreas {
    public inline
    function new( v: InternalLongLatAreas ){ this = v; }
    @:from
    public inline static 
    function fromArray( arr: Array<String> ){
        return new LongLatAreas( { admin_area:       StringTools.trim( arr[0] )
                                , county:            StringTools.trim( arr[1] )
                                , latitude:          Std.parseFloat( arr[2] )
                                , longitude:         Std.parseFloat( arr[3] )
                                , postcodes:         Std.parseInt( arr[4] )
                                , active_postcodes:  Std.parseInt( arr[5] ) 
                                , population:        Std.parseInt( arr[6] )
                                , households:        Std.parseInt( arr[7] )
                             } );
    }
}