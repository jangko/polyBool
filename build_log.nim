import poly_types

type
  LogKind = enum
    lkSelected
    lkChainStart
    lkChainNew
    lkChainMatch
    lkChainRemTail
    lkChainRemHead
    lkChainClose
    lkChainAddHead
    lkChainAddTail
    lkChainReverse
    lkChainConnect
    lkChainJoin
    lkDone
    lkCheck
    lkDivSeg
    lkChop
    lkTempStatus
    lkPopSeg
    lkRemSeg
    lkVert
    lkNewSeg
    lkSegUpdate
    lkRewind
    lkStatus
    lkReset
    lkLog

  LogEntry* = object
    case kind*: LogKind
    of lkSelected:
      segs*: Segments
    of lkChainStart, lkSegUpdate, lkRewind,
      lkRemSeg, lkPopSeg:
      seg*: Segment
    of lkDivSeg, lkChop:
      divSeg*: Segment
      divPt*: PointF
    of lkChainNew:
      pt1*, pt2*: PointF
    of lkChainMatch, lkChainClose, lkChainReverse:
      index*: int
    of lkChainRemTail, lkChainRemHead,
      lkChainAddHead, lkChainAddTail:
      idx*: int
      pt*: PointF
    of lkChainconnect, lkChainJoin:
      index1*, index2*: int
    of lkCheck:
      seg1*, seg2*: Segment
    of lkTempStatus, lkStatus:
      tmpSeg*, tmpBelow*, tmpAbove*: Segment
    of lkVert:
      x*: float64
    of lkNewSeg:
      segNew*: Segment
      primary*: bool
    of lkLog:
      txt*: string
    else: nil

  BuildLog* = ref object
    list: seq[LogEntry]
    nextSegmentId: int
    curVert: float64

proc newBuildLog*(): BuildLog =
  new(result)
  result.list = @[]
  result.nextSegmentId = 0
  result.curVert = 0.0

proc log*(self: BuildLog): seq[LogEntry] =
  self.list

proc segmentId*(self: BuildLog): int =
  result = self.nextSegmentId
  inc self.nextSegmentId

proc checkIntersection*(self: BuildLog, seg1, seg2: Segment) =
  self.list.add(LogEntry(kind: lkCheck, seg1: seg1, seg2: seg2))

proc segmentChop*(self: BuildLog, seg: Segment, stop: PointF) =
  self.list.add(LogEntry(kind: lkDivSeg, seg: seg, pt: stop))
  self.list.add(LogEntry(kind: lkChop, seg: seg, pt: stop))

proc statusRemove*(self: BuildLog, seg: Segment) =
  self.list.add(LogEntry(kind: lkPopSeg, seg: seg))

proc segmentUpdate*(self: BuildLog, seg: Segment) =
  self.list.add(LogEntry(kind: lkSegUpdate, seg: seg))

proc segmentNew*(self: BuildLog, seg: Segment, primary: bool) =
  self.list.add(LogEntry(kind: lkNewSeg, segNew: seg, primary: primary))

proc segmentRemove*(self: BuildLog, seg: Segment) =
  self.list.add(LogEntry(kind: lkRemSeg, seg: seg))

proc tempStatus*(self: BuildLog, seg, above, below: Segment) =
  self.list.add(LogEntry(kind: lkTempStatus, tmpSeg: seg, tmpAbove: above, tmpBelow: below))

proc rewind*(self: BuildLog, seg: Segment) =
  self.list.add(LogEntry(kind: lkRewind, seg: seg))

proc status*(self: BuildLog, seg, above, below: Segment) =
  self.list.add(LogEntry(kind: lkStatus, tmpSeg: seg, tmpAbove: above, tmpBelow: below))

proc vert*(self: BuildLog, x: float64) =
  if x == self.curVert: return
  self.curVert = x
  self.list.add(LogEntry(kind: lkVert, x: x))

proc log*(self: BuildLog, data: string) =
  self.list.add(LogEntry(kind: lkLog, txt: data))

proc reset*(self: BuildLog) =
  self.list.add(LogEntry(kind: lkReset))

proc selected*(self: BuildLog, segs: Segments) =
  self.list.add(LogEntry(kind: lkSelected, segs: segs))

proc chainStart*(self: BuildLog, seg: Segment) =
  self.list.add(LogEntry(kind: lkChainStart, seg: seg))

proc chainRemoveHead*(self: BuildLog, index: int, pt: PointF) =
  self.list.add(LogEntry(kind: lkChainRemHead, idx: index, pt: pt))

proc chainRemoveTail*(self: BuildLog, index: int, pt: PointF) =
  self.list.add(LogEntry(kind: lkChainRemTail, idx: index, pt: pt))

proc chainNew*(self: BuildLog, pt1, pt2: PointF) =
  self.list.add(LogEntry(kind: lkChainNew, pt1: pt1, pt2: pt2))

proc chainMatch*(self: BuildLog, index: int) =
  self.list.add(LogEntry(kind: lkChainMatch, index: index))

proc chainClose*(self: BuildLog, index: int) =
  self.list.add(LogEntry(kind: lkChainClose, index: index))

proc chainAddHead*(self: BuildLog, index: int, pt: PointF) =
  self.list.add(LogEntry(kind: lkChainAddHead, index: index, pt: pt))

proc chainAddTail*(self: BuildLog, index: int, pt: PointF) =
  self.list.add(LogEntry(kind: lkChainAddTail, index: index, pt: pt))

proc chainConnect*(self: BuildLog, index1, index2: int) =
  self.list.add(LogEntry(kind: lkChainConnect, index1: index1, index2: index2))

proc chainReverse*(self: BuildLog, index: int) =
  self.list.add(LogEntry(kind: lkChainReverse, index: index))

proc chainJoin*(self: BuildLog, index1, index2: int) =
  self.list.add(LogEntry(kind: lkChainJoin, index1: index1, index2: index2))

proc done*(self: BuildLog) =
  self.list.add(LogEntry(kind: lkDone))
