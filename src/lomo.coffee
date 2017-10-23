class OverlappingMarkerOptimizer
  constructor: (@map, @markers, opts = {}) ->

  makeHighlightListeners: (marker) =>
    _this = this
    {
      highlight: ->
        marker['_omsData'].leg.setStyle color: _this['legColors']['highlighted']
      unhighlight: ->
        marker['_omsData'].leg.setStyle color: _this['legColors']['usual']
    }

  sortMarkersByX: (markers) ->
    x1_array = []
    x2_array = []
    centerX = @map.getCenter().lng
    i = 0
    while i < markers.length
      marker = markers[i]
      if marker.getLatLng().lng < centerX
        x1_array.push marker
      else
        x2_array.push marker
      ++i
    [
      x1_array
      x2_array
    ]

  sortMarkersByY: (markers) ->
    markers.sort (a, b) ->
      b.getLatLng().lat - a.getLatLng().lat

  pullMarkers: (markers, side) ->
    maxY = @map.getPixelBounds().max.y
    minX = @map.latLngToLayerPoint(L.latLng([0, 0])).x
    maxX = @map.getPixelBounds().max.x
    console.log minX
    i = 0
    while i < markers.length
      marker = markers[i]
      if side == 'left'
        groupX = minX - 45
      else
        groupX = maxX + 45
      pt = new (L.Point)(groupX, 23 + maxY + 50 * i)
      footLl = @map.containerPointToLatLng(pt)

      leg = new (L.Polyline)([
        marker.getLatLng()
        footLl
      ],
        color: @['legColors']['usual']
        weight: @['legWeight']
        clickable: false)
      @map.addLayer leg
      marker['_omsData'] =
        usualPosition: marker.getLatLng()
        leg: leg
      if @['legColors']['highlighted'] != @['legColors']['usual']
        mhl = @makeHighlightListeners(marker)
        marker['_omsData'].highlightListeners = mhl
        marker.addEventListener 'mouseover', mhl.highlight
        marker.addEventListener 'mouseout', mhl.unhighlight
      marker.setLatLng footLl
      # marker.setZIndexOffset(1000000);
      ++i
    return

    spiderfy: = ->
      xGroups = @sortMarkersByX(@markers)
      markersX1 = xGroups[0]
      markersX2 = xGroups[1]

      sortedX1Markers = @sortMarkersByY(markersX1)
      sortedX2Markers = @sortMarkersByY(markersX2)

      @pullMarkers sortedX1Markers, 'left'
      @pullMarkers sortedX2Markers, 'right'
      @spiderfied = true
      return

    unspiderfy: = ->
      if @spiderfied == null
        return this

      @unspiderfying = true

      _ref = @markers
      _i = 0
      _len = _ref.length
      while _i < _len
        marker = _ref[_i]
        if marker['_omsData'] != null
          @map.removeLayer marker['_omsData'].leg
          marker.setLatLng marker['_omsData'].usualPosition
          marker.setZIndexOffset 0
          mhl = marker['_omsData'].highlightListeners
          if mhl != null
            marker.removeEventListener 'mouseover', mhl.highlight
            marker.removeEventListener 'mouseout', mhl.unhighlight
          delete marker['_omsData']
        _i++
      delete @unspiderfying
      delete @spiderfied
      this