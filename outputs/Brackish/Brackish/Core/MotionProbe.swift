import UIKit

#if DEBUG
/// Diagnostic callback cadence only. This is not a GPU render-time measurement.
@MainActor final class MotionProbe:NSObject {
    static let shared=MotionProbe()
    private var link:CADisplayLink?
    private var samples:[Double]=[]
    private var previous:CFTimeInterval?
    private var started:CFTimeInterval=0
    func startIfRequested() {
        guard ProcessInfo.processInfo.arguments.contains("--measure-motion"),link == nil else{return}
        started=CACurrentMediaTime();samples=[];previous=nil
        let link=CADisplayLink(target:self,selector:#selector(tick(_:)))
        link.preferredFrameRateRange=CAFrameRateRange(minimum:60,maximum:60,preferred:60)
        link.add(to:.main,forMode:.common);self.link=link
    }
    @objc private func tick(_ sender:CADisplayLink) {
        if let previous {samples.append((sender.timestamp-previous)*1000)}
        previous=sender.timestamp
        if CACurrentMediaTime()-started > 45 {finish()}
    }
    private func finish() {
        link?.invalidate();link=nil
        let sorted=samples.sorted();guard !sorted.isEmpty else{return}
        let percentile:(Double)->Double={p in sorted[min(sorted.count-1,Int(Double(sorted.count-1)*p))]}
        let payload:[String:Any]=["kind":"Simulator CADisplayLink callback intervals; not GPU frame timings","requestedHz":60,"durationSeconds":45,"samples":samples.count,"medianMs":percentile(0.5),"p95Ms":percentile(0.95),"p99Ms":percentile(0.99),"maxMs":sorted.last!,"intervalsAbove25ms":samples.filter{$0>25}.count,"intervalsMs":samples]
        if let data=try? JSONSerialization.data(withJSONObject:payload,options:[.prettyPrinted,.sortedKeys]) {
            let url=FileManager.default.urls(for:.documentDirectory,in:.userDomainMask)[0].appendingPathComponent("motion-cadence.json");try? data.write(to:url,options:.atomic)
        }
    }
}
#endif
