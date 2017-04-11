import build_log, epsilon, poly_types

proc indexBuilder(seg: Segment): int =
  result = 0
  if seg.myFill.above: inc(result, 8)
  if seg.myFill.below: inc(result, 4)
  if seg.otherFill.above: inc(result, 2)
  if seg.otherFill.below: inc result

proc segmentSelect(segments: Segments, selection: array[16, int], buildLog: BuildLog): Segments =
  result = @[]

  for seg in segments:
    let index = seg.indexBuilder()
    if selection[index] != 0:
      # copy the segment to the results, while also calculating the fill status
      var res = Segment()
      res.id = if buildLog != nil: buildLog.segmentId() else: -1
      res.start = seg.start
      res.stop  = seg.stop
      res.myFill.above = selection[index] == 1  # 1 if filled above
      res.myFill.below = selection[index] == 2  # 2 if filled below
      res.otherFill.above = false
      res.otherFill.below = false
      result.add res

  if buildLog != nil:
    buildLog.selected(result)

# primary | secondary
proc selectUnion*(segments: Segments, buildLog: BuildLog): Segments =
  # above1 below1 above2 below2    Keep?               Value
  #    0      0      0      0   =>   no                  0
  #    0      0      0      1   =>   yes filled below    2
  #    0      0      1      0   =>   yes filled above    1
  #    0      0      1      1   =>   no                  0
  #    0      1      0      0   =>   yes filled below    2
  #    0      1      0      1   =>   yes filled below    2
  #    0      1      1      0   =>   no                  0
  #    0      1      1      1   =>   no                  0
  #    1      0      0      0   =>   yes filled above    1
  #    1      0      0      1   =>   no                  0
  #    1      0      1      0   =>   yes filled above    1
  #    1      0      1      1   =>   no                  0
  #    1      1      0      0   =>   no                  0
  #    1      1      0      1   =>   no                  0
  #    1      1      1      0   =>   no                  0
  #    1      1      1      1   =>   no                  0
  const selection = [
    0, 2, 1, 0,
    2, 2, 0, 0,
    1, 0, 1, 0,
    0, 0, 0, 0]
  result = segmentSelect(segments, selection, buildLog)

# primary & secondary
proc selectIntersect*(segments: Segments, buildLog: BuildLog): Segments =
  # above1 below1 above2 below2    Keep?               Value
  #    0      0      0      0   =>   no                  0
  #    0      0      0      1   =>   no                  0
  #    0      0      1      0   =>   no                  0
  #    0      0      1      1   =>   no                  0
  #    0      1      0      0   =>   no                  0
  #    0      1      0      1   =>   yes filled below    2
  #    0      1      1      0   =>   no                  0
  #    0      1      1      1   =>   yes filled below    2
  #    1      0      0      0   =>   no                  0
  #    1      0      0      1   =>   no                  0
  #    1      0      1      0   =>   yes filled above    1
  #    1      0      1      1   =>   yes filled above    1
  #    1      1      0      0   =>   no                  0
  #    1      1      0      1   =>   yes filled below    2
  #    1      1      1      0   =>   yes filled above    1
  #    1      1      1      1   =>   no                  0
  const selection = [
    0, 0, 0, 0,
    0, 2, 0, 2,
    0, 0, 1, 1,
    0, 2, 1, 0]
  result = segmentSelect(segments, selection, buildLog)
  
# primary - secondary
proc selectDifference*(segments: Segments, buildLog: BuildLog): Segments =
  # above1 below1 above2 below2    Keep?               Value
  #    0      0      0      0   =>   no                  0
  #    0      0      0      1   =>   no                  0
  #    0      0      1      0   =>   no                  0
  #    0      0      1      1   =>   no                  0
  #    0      1      0      0   =>   yes filled below    2
  #    0      1      0      1   =>   no                  0
  #    0      1      1      0   =>   yes filled below    2
  #    0      1      1      1   =>   no                  0
  #    1      0      0      0   =>   yes filled above    1
  #    1      0      0      1   =>   yes filled above    1
  #    1      0      1      0   =>   no                  0
  #    1      0      1      1   =>   no                  0
  #    1      1      0      0   =>   no                  0
  #    1      1      0      1   =>   yes filled above    1
  #    1      1      1      0   =>   yes filled below    2
  #    1      1      1      1   =>   no                  0
  const selection = [
    0, 0, 0, 0,
    2, 0, 2, 0,
    1, 1, 0, 0,
    0, 1, 2, 0]
  result = segmentSelect(segments, selection, buildLog)
  
# secondary - primary  
proc selectDifferenceRev*(segments: Segments, buildLog: BuildLog): Segments =
  # above1 below1 above2 below2    Keep?               Value
  #    0      0      0      0   =>   no                  0
  #    0      0      0      1   =>   yes filled below    2
  #    0      0      1      0   =>   yes filled above    1
  #    0      0      1      1   =>   no                  0
  #    0      1      0      0   =>   no                  0
  #    0      1      0      1   =>   no                  0
  #    0      1      1      0   =>   yes filled above    1
  #    0      1      1      1   =>   yes filled above    1
  #    1      0      0      0   =>   no                  0
  #    1      0      0      1   =>   yes filled below    2
  #    1      0      1      0   =>   no                  0
  #    1      0      1      1   =>   yes filled below    2
  #    1      1      0      0   =>   no                  0
  #    1      1      0      1   =>   no                  0
  #    1      1      1      0   =>   no                  0
  #    1      1      1      1   =>   no                  0
  const selection = [
    0, 2, 1, 0,
    0, 0, 1, 1,
    0, 2, 0, 2,
    0, 0, 0, 0]
  result = segmentSelect(segments, selection, buildLog)
  
# primary ^ secondary
proc selectXor*(segments: Segments, buildLog: BuildLog): Segments =
  # above1 below1 above2 below2    Keep?               Value
  #    0      0      0      0   =>   no                  0
  #    0      0      0      1   =>   yes filled below    2
  #    0      0      1      0   =>   yes filled above    1
  #    0      0      1      1   =>   no                  0
  #    0      1      0      0   =>   yes filled below    2
  #    0      1      0      1   =>   no                  0
  #    0      1      1      0   =>   no                  0
  #    0      1      1      1   =>   yes filled above    1
  #    1      0      0      0   =>   yes filled above    1
  #    1      0      0      1   =>   no                  0
  #    1      0      1      0   =>   no                  0
  #    1      0      1      1   =>   yes filled below    2
  #    1      1      0      0   =>   no                  0
  #    1      1      0      1   =>   yes filled above    1
  #    1      1      1      0   =>   yes filled below    2
  #    1      1      1      1   =>   no                  0
  const selection = [
    0, 2, 1, 0,
    2, 0, 0, 1,
    1, 0, 0, 2,
    0, 1, 2, 0]
  result = segmentSelect(segments, selection, buildLog)
