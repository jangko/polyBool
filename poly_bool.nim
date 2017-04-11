import build_log, epsilon, intersecter, segment_chainer, segment_selector, poly_types

type
  PolyBool* = object
    log: BuildLog
    eps: Epsilon

proc initPolyBool*(): PolyBool =
  result.log = nil
  result.eps = initEpsilon()

proc buildLog*(self: var PolyBool, bl: bool) =
  if bl: self.log = newBuildLog()
  else: self.log = nil

proc buildLog*(self: PolyBool): auto =
  if self.log != nil: result = self.log.log()

  # getter/setter for epsilon
proc epsilon*(self: var PolyBool, v: float64) =
  self.eps.epsilon(v)

proc epsilon*(self: var PolyBool): var Epsilon =
  self.eps

# core API
type
  Polygon* = object
    regions: seq[seq[PointF]]
    inverted: bool

  Segmented* = object
    segments: Segments
    inverted: bool

  Combined* = object
    combined: Segments
    inverted1, inverted2: bool

proc segments*(self: PolyBool, poly: Polygon): Segmented =
  var api = intersecter(true, self.eps, self.log)
  for region in poly.regions:
    api.addRegion(region)

  result.segments = api.calculateSegmented(poly.inverted)
  result.inverted = poly.inverted

proc combine*(self: PolyBool, segments1, segments2: Segmented): Combined =
  var api = intersecter(false, self.eps, self.log)
  result.combined  = api.calculateCombined(segments1.segments, segments1.inverted,
    segments2.segments, segments2.inverted)
  result.inverted1 = segments1.inverted
  result.inverted2 = segments2.inverted

proc selectUnion*(self: PolyBool, combined: Combined): Segmented =
  result.segments = selectUnion(combined.combined, self.log)
  result.inverted = combined.inverted1 or combined.inverted2

proc selectIntersect*(self: PolyBool, combined: Combined): Segmented =
  result.segments = selectIntersect(combined.combined, self.log)
  result.inverted = combined.inverted1 and combined.inverted2

proc selectDifference*(self: PolyBool, combined: Combined): Segmented =
  result.segments = selectDifference(combined.combined, self.log)
  result.inverted = combined.inverted1 and not combined.inverted2

proc selectDifferenceRev*(self: PolyBool, combined: Combined): Segmented =
  result.segments = selectDifferenceRev(combined.combined, self.log)
  result.inverted = not combined.inverted1 and combined.inverted2

proc selectXor*(self: PolyBool, combined: Combined): Segmented =
  result.segments = selectXor(combined.combined, self.log)
  result.inverted = combined.inverted1 != combined.inverted2

proc polygon*(self: PolyBool, segments: Segmented): Polygon =
  result.regions = segmentChainer(segments.segments, self.eps, self.log)
  result.inverted = segments.inverted

type
  Selector = proc(self: PolyBool, combined: Combined): Segmented

proc operate(self: PolyBool, poly1, poly2: Polygon, selector: Selector): Polygon =
  var
    seg1 = self.segments(poly1)
    seg2 = self.segments(poly2)
    comb = self.combine(seg1, seg2)
    seg3 = self.selector(comb)
  self.polygon(seg3)

# helper functions for common operations
proc clipUnion*(self: PolyBool, poly1, poly2: Polygon): Polygon =
  self.operate(poly1, poly2, selectUnion)

proc clipIntersect*(self: PolyBool, poly1, poly2: Polygon): Polygon =
  self.operate(poly1, poly2, selectIntersect)

proc clipDifference*(self: PolyBool, poly1, poly2: Polygon): Polygon =
  self.operate(poly1, poly2, selectDifference)

proc clipDifferenceRev*(self: PolyBool, poly1, poly2: Polygon): Polygon =
  self.operate(poly1, poly2, selectDifferenceRev)

proc clipXor*(self: PolyBool, poly1, poly2: Polygon): Polygon =
  self.operate(poly1, poly2, selectXor)
