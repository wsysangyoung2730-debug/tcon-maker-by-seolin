import SwiftUI

extension Color {
    static let seolin=Color(red:32/255,green:46/255,blue:120/255)
    static let appBackground=Color(uiColor:.systemGroupedBackground)
    static let panel=Color(uiColor:.secondarySystemGroupedBackground)
}
struct PrimaryButton:View {
    let title:String
    var icon:String?=nil
    var action:()->Void
    var body:some View {
        Button(action:action){HStack(spacing:10){if let icon{Image(systemName:icon)};Text(title).fontWeight(.semibold)}.frame(maxWidth:.infinity).padding(.vertical,17)}
            .buttonStyle(.plain).foregroundStyle(.white).background(Color.seolin,in:RoundedRectangle(cornerRadius:16))
    }
}
struct PhotoThumbnail:View {
    let photo:PhotoItem
    var body:some View {
        ZStack {
            Checkerboard()
            if let image=photo.image {Image(uiImage:image).resizable().scaledToFit()}
            else {Image(systemName:"photo.badge.exclamationmark").font(.largeTitle).foregroundStyle(.secondary)}
        }.accessibilityLabel(photo.name)
    }
}
struct Checkerboard:View {
    var body:some View {Canvas{context,size in
        context.fill(Path(CGRect(origin:.zero,size:size)),with:.color(.white))
        let step:CGFloat=12
        for y in stride(from:CGFloat.zero,to:size.height,by:step){for x in stride(from:CGFloat.zero,to:size.width,by:step) where (Int(x/step)+Int(y/step))%2==0{context.fill(Path(CGRect(x:x,y:y,width:step,height:step)),with:.color(.gray.opacity(0.13)))}}
    }}
}
struct ValueSlider:View {
    let title:String
    @Binding var value:Double
    var range:ClosedRange<Double>
    var step:Double=1
    var suffix=""
    var onCommit:()->Void={}
    @State private var number=""
    @State private var editing=false
    var body:some View {
        VStack(spacing:10){
            HStack{Text(title);Spacer();Button("\(value.formatted(.number.precision(.fractionLength(0...2))))\(suffix)"){number=String(value);editing=true}.monospacedDigit().fontWeight(.medium).accessibilityLabel("\(title) 숫자 입력")}
            Slider(value:$value,in:range,step:step,onEditingChanged:{if !$0{onCommit()}}).accessibilityLabel(title)
        }.padding(.vertical,5)
        .alert(title,isPresented:$editing){TextField("값",text:$number).keyboardType(.numbersAndPunctuation);Button("취소",role:.cancel){};Button("적용"){if let n=Double(number),n.isFinite{value=n.finiteClamped(range,fallback:value);onCommit()}}}message:{Text("\(range.lowerBound.formatted()) ~ \(range.upperBound.formatted())\(suffix)")}
    }
}
struct ChoiceRow:View {
    let title:String
    @Binding var selection:String
    let choices:[(String,String)]
    var onChange:()->Void={}
    var body:some View {VStack(alignment:.leading,spacing:10){Text(title).font(.subheadline).foregroundStyle(.secondary);Picker(title,selection:$selection){ForEach(choices,id:\.0){key,label in Text(label).tag(key)}}.pickerStyle(.segmented).onChange(of:selection){_,_ in onChange()}}}
}
struct StatusPill:View {
    let warning:Bool
    var body:some View {Label(warning ? "확인 필요":"완료",systemImage:warning ? "exclamationmark.circle.fill":"checkmark.circle.fill").font(.caption.weight(.medium)).foregroundStyle(warning ? Color.orange:Color.green).padding(.horizontal,8).padding(.vertical,5).background((warning ? Color.orange:Color.green).opacity(0.1),in:Capsule())}
}
