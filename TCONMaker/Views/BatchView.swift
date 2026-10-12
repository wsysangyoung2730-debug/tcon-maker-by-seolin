import SwiftUI

struct BatchView:View {
    @EnvironmentObject private var store:PhotoStore
    @State private var settings=false
    @State private var reviewOnly=false
    @State private var selecting=false
    @State private var selection=Set<Int>()
    @State private var deletePrompt=false
    private var displayed:[PhotoItem]{store.photos.filter{!reviewOnly || $0.needsReview}}
    private var exportIDs:[Int]{store.photos.filter{$0.status=="done" && (!selecting || selection.contains($0.id))}.map(\.id)}
    var body:some View {
        ScrollView {
            VStack(alignment:.leading,spacing:18){
                Text("\(store.photos.count)장의 사진").font(.largeTitle.bold())
                Text(selecting ? "저장하거나 삭제할 사진을 선택하세요":"사진을 눌러 개별 조정하세요").foregroundStyle(.secondary).font(.subheadline)
                Button{settings=true}label:{HStack{Text("\(store.settings.presetName) · \(store.settings.dimensions)");Spacer();Image(systemName:"slider.horizontal.3");Text("전체 설정").fontWeight(.semibold)}.font(.subheadline).padding(16).background(Color.seolin.opacity(0.07),in:RoundedRectangle(cornerRadius:14))}.accessibilityIdentifier("batchSettings")
                Picker("사진 상태",selection:$reviewOnly){Text("전체 \(store.photos.count)").tag(false);Text("확인 필요 \(store.photos.filter(\.needsReview).count)").tag(true)}.pickerStyle(.segmented)
                if displayed.isEmpty {ContentUnavailableView("확인할 사진이 없어요",systemImage:"checkmark.circle",description:Text("모든 사진을 확인했습니다."))}
                LazyVGrid(columns:[GridItem(.adaptive(minimum:145,maximum:250),spacing:12)],spacing:14){ForEach(displayed){photo in
                    Button{if selecting{if selection.contains(photo.id){selection.remove(photo.id)}else{selection.insert(photo.id)}}else{store.path.append(.editor(photo.id))}}label:{VStack(alignment:.leading,spacing:0){
                        PhotoThumbnail(photo:photo).aspectRatio(0.8,contentMode:.fit).overlay(alignment:.topTrailing){if selecting{Image(systemName:selection.contains(photo.id) ? "checkmark.circle.fill":"circle").font(.title2).foregroundStyle(Color.seolin).padding(8)}else if photo.custom{Image(systemName:"slider.horizontal.3").font(.caption).padding(8).foregroundStyle(.white).background(Color.brandNavy,in:Circle()).padding(8)}}
                        HStack{Text(photo.name).font(.caption.weight(.medium)).lineLimit(1);Spacer(minLength:2);StatusPill(warning:photo.needsReview)}.padding(10)
                    }.background(Color.panel,in:RoundedRectangle(cornerRadius:16)).clipShape(RoundedRectangle(cornerRadius:16)).overlay(RoundedRectangle(cornerRadius:16).stroke(Color.secondary.opacity(0.12)))}.buttonStyle(.plain).accessibilityIdentifier("photo-\(photo.id)")
                    .contextMenu{Button("사진 삭제",role:.destructive){selection=[photo.id];deletePrompt=true}}
                }}
            }.padding(20).frame(maxWidth:850)
        }.background(Color.appBackground)
        .navigationTitle("사진 작업").navigationBarTitleDisplayMode(.inline).toolbar(.visible,for:.navigationBar)
        .toolbar{
            ToolbarItemGroup(placement:.topBarTrailing){Button(selecting ? "취소":"선택"){selecting.toggle();selection=[]};ImportActions(compact:true);Menu{Button("모두 삭제",role:.destructive){selection=Set(store.photos.map(\.id));deletePrompt=true}}label:{Image(systemName:"ellipsis.circle")}.accessibilityLabel("사진 관리")}
        }
        .safeAreaInset(edge:.bottom){VStack(spacing:10){if selecting && !selection.isEmpty{Button("선택한 \(selection.count)장 삭제",role:.destructive){deletePrompt=true}};Text("원본 사진은 변경되지 않아요").font(.caption).foregroundStyle(.secondary);PrimaryButton(title:"\(exportIDs.count)장 저장하기",icon:"square.and.arrow.down"){store.path.append(.export(exportIDs))}.disabled(exportIDs.isEmpty).opacity(exportIDs.isEmpty ? 0.5:1).accessibilityIdentifier("batchExport")}.padding(20).background(.regularMaterial)}
        .sheet(isPresented:$settings){SettingsView(draft:store.settings)}
        .confirmationDialog("선택한 \(selection.count)장을 작업 목록에서 삭제할까요?",isPresented:$deletePrompt,titleVisibility:.visible){Button("작업 목록에서 삭제",role:.destructive){let ids=Array(selection);selection=[];Task{await store.remove(ids)}}}message:{Text("원본 사진은 삭제되지 않습니다.")}
    }
}
