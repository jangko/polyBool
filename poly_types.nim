type
  PointF* = object
    x*, y*: float64
    
  SegmentFill* = object
    above*, below*: bool
    
  Segment* = ref object
    id*: int
    start*, stop*: PointF
    myFill*, otherFill*: SegmentFill
    
  Segments* = seq[Segment]
