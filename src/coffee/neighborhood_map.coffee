#!/usr/bin/env/coffee


### Class Menu_View ###
###*
 * A Menu_View is a view of the neighborhood places as a list of clickable items
 * @constructor
 * @param {Neighborhood_Map} app - the main neighborhood map instance
###
class Menu_View

  ### constructor ###
  constructor: (@app) ->
    @menu_Element = document.getElementById('menu-view')
    @menu_Button = document.getElementById('menu-button')
    @hidden = ko.observable(false)

  ###*
   * method toggle()
   * toggles the visibility of the menu
  ###
  toggle: => @hidden(not @hidden())


### Class Map_View ###
###*
 * A Map_View is a view of the neighbohood places on a map.
 * @constructor
 * @param {Neighborhood_Map} app - the main neighborhood map instance
###
class Map_View

  ### constructor ###
  constructor: (@app) ->
    @map_Element = document.getElementById('map-view')
    @gm_request = @app.google_Maps.get({
      query: { libraries: 'places' }
      success: @init
      error: @error
      msec: 3000
    })

  init: =>
    @map = new google.maps.Map( @map_Element, {
      center: { lat: 30.2712406, lng: -97.7555901 }, 
      scrollwheel: true,
      zoom: 13,
      disableDefaultUI: true,
      callback: @error
    })
    @app.map_Ready()
      
  error: (err) =>
    window.alert("Google Maps is currently unavailable")


### Class Marker_View ###
###*
 * A Marker_View is a view of a place as a map marker on the map.
 * @constructor
 * @param {PLace} place - an instance of the Place class 
 * @param {Map_View} map_View - an instance of the Map_View class 
###
class Marker_View

  marker_Icon = "https://maps.google.com/mapfiles/ms/icons/green-dot.png"
  marker_Highlight_Icon = "https://maps.google.com/mapfiles/ms/icons/blue-dot.png"

  ### constructor ###
  constructor: (@place, @map_View) ->
    @marker = new google.maps.Marker({
      position: @place.loc,
      optimized: false,
      zIndex:1000,
      map: @map_View.map,
      title: @place.name(),
      icon: marker_Icon,
      opacity: 1.0
    })
    @marker.addListener('click', @place.click)
    @place.visible.subscribe(@display)
    @place.selected.subscribe(@highlight)

  ### method display() ###
  display: (show_marker) =>
    @marker.setVisible(show_marker)

  ### method highlight() ###
  highlight: (hl_true) =>
    if hl_true
      @marker.setIcon(marker_Highlight_Icon)
      @marker.setZIndex(1001)
    else
      @marker.setIcon(marker_Icon)
      @marker.setZIndex(1000)


### Class Info_View ###
###*
 * An Info_View is a view of a Place as a popup InfoWindow
 * @constructor
 * @param {Place} place
 * @param {Map_View} map_View
 * @param {Marker_View} marker_View
###
class Info_View

  ### constructor ###
  constructor: (@place, @map_View, @marker_View) ->
    @wikipedia_Info = undefined
    s = '<span class="error-msg"> Wikipedia is currently unavailable. </span> <br>'
    @error_Msg = s + '<span class="error-msg"> Please try again later. </span>'
    @info_Window = new google.maps.InfoWindow( maxWidth: 250 )
    @info_Window.addListener('closeclick', @place.click)
    @place.show_info.subscribe(@display)

  ###*
   * method display_Info()
   * helper function for method display_Wikipedia_Info()
   * @param {Object} obj - contains title, description and url
  ###
  display_Info: (obj) =>
    s = '' +
      '<div class="info-window">' +
      '<h1 class="info-window-h1">' + obj.title + '</h1>' +
      '<p class="info-window-p">' + obj.description + '</p>' + 
      '<a href="' + obj.url + '" target="_blank"> Wikipedia </a>' +
      '</div>'
    @info_Window.setContent(s)
    @info_Window.open(@map_View.map, @marker_View.marker)

  ###*
   * method display_Wikipedia_Info()
   * display either the info from wikipedia or an error message
   * @param {Boolean} show_marker - to display or not display
  ###
  display_Wikipedia_Info: =>
    if typeof(@wikipedia_Info) != 'undefined'
      @display_Info(@wikipedia_Info)
    else
      @place.app.wikipedia.openSearch( {
        search_Str: @place.wikipedia_Title,
        success: ((data) =>
          @wikipedia_Info = {
            title: data[1][0],
            description: data[2][0]
            url: data[3][0]
          }
          @display_Info(@wikipedia_Info)),
        error: (=>
          @display_Info({
            title: @place.name(),
            description: @error_Msg,
            url: "https://en.wikipedia.org/"}))
        })

  ###*
   * method display()
   * @param {Boolean} show_window - to display or not display
  ###
  display: (show_Window) =>
    if show_Window
      @display_Wikipedia_Info()
    else
      @info_Window.close()



### Class Place ###
###*
 * A Place is part of the view model.  It is constructed from a simple object
 * and is associated with a Marker_View, an Info_View and a
 * div.menu-list-item element as part of the Menu_View.
 * @constructor
 * @param {object} obj - a simple object containing the name, location and wikipedia title
 * @param {Neighborhood_Map} @app - the main app instance
###
class Place

  ### constructor ###
  constructor: (obj, @app) ->
    @loc = obj.loc
    @name = ko.observable(obj.name)
    @wikipedia_Title = obj.wikipedia_title
    @state = ko.observable(1)
    @hidden = ko.computed(=> @state() == 0)
    @visible = ko.computed(=> @state() > 0)
    @selected = ko.computed(=> @state() > 1)
    #@show_info = ko.computed(=> @state() > 2)
    @show_info = ko.computed(=> @state() > 1)

  map_Ready: =>
    @marker_View = new Marker_View(this, @app.map_View)
    @info_View = new Info_View(this, @app.map_View, @marker_View)
    
  ###*
   * method click() handles all clicks whether on the menu items or
   * on the map markers and cycles through the states appropriately
  ###
  click: =>
    
    ### de-select all other places ###
    for place in @app.places()
      if place != this and place.state() > 1
        place.state(1)
        
    ### change to next state ###
    #@state([1,2,3,2][@state()])
    @state([1,2,1][@state()])

    ### hide the menu after selection when in cell phone mode. ###
    if window.innerWidth < 700
      @app.menu_View.hidden(true)

  ###*
   * method display
   * @param {Boolean} boolean_expr - to display or not display
  ###
  display: (bool_expr) =>
    if bool_expr
      @state(Math.max(1, @state()))
    else
      @state(0)


### Class Neighborhood_Map ###
###*
 * An instance of class Neighborhood_Map is the main app.
 * @constructor
###
class Neighborhood_Map

  ### constructor ###
  constructor: ->
    @wikipedia = new Wikipedia_API('Map of Austin places')
    @google_Maps = new Google_Maps_API("AIzaSyBjtVDpeVL8JzhYqCXt8d6E3bRanaNCXEo")
    @places = ko.observableArray([])
    @menu_View = new Menu_View(this)
    @map_View = new Map_View(this)
    @app_Element = document.getElementById('neighborhood-map')
    @search_Str = ko.observable('')
    @search_Str.subscribe(@search)
    ko.applyBindings( this, @app_Element)

  ###*
   * method map_Ready
  ###
  map_Ready: =>
    for place in @places()
      place.map_Ready()
      
  ###*
   * method init
   * @param {Array} places - an array of simple place objects
  ###
  init: (places) =>
    @places([])
    for obj in places
      @places.push(new Place(obj, this))

  ###*
   * method search
   * @param {String} pat - the patern to search for
  ###
  search: (pat) =>
    expr = RegExp(pat,'i')
    for place in @places()
      place.display(expr.test(place.name()))



if window?
  window.Neighborhood_Map = Neighborhood_Map
