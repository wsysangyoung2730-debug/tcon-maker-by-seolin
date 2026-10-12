import SwiftUI
import PhotosUI
import AVFoundation

struct RootView:View {
    @StateObject private var store=PhotoStore()
    var body:some View {
        NavigationStack(path:$store.path){
            StartView()
                .navigationDestination(for:AppRoute.self){route in
                    switch route {
                    case .batch:BatchView()
                    case .editor(let id):EditorView(initialID:id)
                    case .export(let ids):ExportView(ids:ids)
                    }
                }
        }
        .background(EngineHost(engine:store.engine).frame(width:2,height:2).opacity(0.01).accessibilityHidden(true))
        .environmentObject(store).tint(.seolin)
        .overlay{if store.busy{ZStack{Color.black.opacity(0.18).ignoresSafeArea();VStack(spacing:16){ProgressView();Text(store.progress.isEmpty ? "처리 중…":store.progress).font(.subheadline.weight(.medium))}.padding(28).background(.regularMaterial,in:RoundedRectangle(cornerRadius:20))}.accessibilityIdentifier("processingOverlay")}}
        .alert("작업을 확인해 주세요",isPresented:Binding(get:{store.error != nil},set:{if !$0{store.error=nil}})){Button("확인",role:.cancel){store.error=nil}}message:{Text(store.error ?? "")}
        .alert("안내",isPresented:Binding(get:{store.notice != nil},set:{if !$0{store.notice=nil}})){Button("확인",role:.cancel){store.notice=nil}}message:{Text(store.notice ?? "")}
        .task{await store.prepare()}
    }
}

struct ImportActions:View {
    @EnvironmentObject private var store:PhotoStore
    @State private var picks:[PhotosPickerItem]=[]
    @State private var camera=false
    @State private var files=false
    var compact=false
    var body:some View {
        Group {
            if compact {
                Menu {
                    PhotosPicker(selection:$picks,maxSelectionCount:30,matching:.images,preferredItemEncoding:.current){Label("사진 보관함",systemImage:"photo.on.rectangle")}
                    Button("파일에서 가져오기",systemImage:"folder"){files=true}
                    Button("촬영하기",systemImage:"camera"){openCamera()}
                }label:{Image(systemName:"plus").font(.title3).frame(width:44,height:44)}.accessibilityLabel("사진 추가")
            } else {
                VStack(spacing:12){
                    PhotosPicker(selection:$picks,maxSelectionCount:30,matching:.images,preferredItemEncoding:.current){Label("사진 선택하기",systemImage:"photo").font(.headline).frame(maxWidth:.infinity).padding(.vertical,18).foregroundStyle(.white).background(Color.brandNavy,in:RoundedRectangle(cornerRadius:16))}.accessibilityIdentifier("importPhotos")
                    Button(action:openCamera){Label("촬영하기",systemImage:"camera").font(.headline).frame(maxWidth:.infinity).padding(.vertical,16).overlay(RoundedRectangle(cornerRadius:16).stroke(Color.seolin,lineWidth:1))}
                    Button("파일에서 가져오기",systemImage:"folder"){files=true}.font(.subheadline).padding(.top,3)
                }
            }
        }.disabled(!store.ready || store.busy)
        .onChange(of:picks){_,items in guard !items.isEmpty else{return};picks=[];Task{await store.importSelections(items)}}
        .fileImporter(isPresented:$files,allowedContentTypes:[.image],allowsMultipleSelection:true){result in switch result{case .success(let urls):Task{await store.importFiles(urls)};case .failure(let error):store.error=error.localizedDescription}}
        .fullScreenCover(isPresented:$camera){CameraPicker{image in Task{await store.importCamera(image)}}.ignoresSafeArea()}
    }
    private func openCamera(){
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else{store.error="이 기기에서는 카메라를 사용할 수 없어요. 사진 보관함이나 파일에서 가져와 주세요.";return}
        Task {let permission=AVCaptureDevice.authorizationStatus(for:.video);let allowed=permission == .authorized ? true : permission == .notDetermined ? await AVCaptureDevice.requestAccess(for:.video) : false
            if allowed{camera=true}else{store.error="카메라 권한이 꺼져 있어요. 아이폰 설정에서 카메라 권한을 켜 주세요."}}
    }
}

struct StartView:View {
    @EnvironmentObject private var store:PhotoStore
    @State private var settings=false
    var body:some View {
        ScrollView {
            VStack(alignment:.leading,spacing:20){
                HStack(spacing:12){Image("SeolinBox").resizable().scaledToFit().frame(width:46,height:46).accessibilityHidden(true);VStack(alignment:.leading,spacing:2){Text("TCON Maker").font(.title2.bold());Text("by SEOLIN").font(.caption).foregroundStyle(.secondary)};Spacer();Button{settings=true}label:{Image(systemName:"gearshape").font(.title2).frame(width:44,height:44)}.accessibilityLabel("전체 설정").accessibilityIdentifier("openSettings")}
                VStack(alignment:.leading,spacing:12){Text("심사 사진 준비를\n간편하게").font(.system(size:34,weight:.bold));Text("사진을 고르면 크기와 구도를 맞춰드려요").font(.subheadline).foregroundStyle(.secondary)}
                ZStack {
                    RoundedRectangle(cornerRadius:24).fill(Color.seolin.opacity(0.05))
                    VStack(spacing:12){Image("DemoPortrait").resizable().scaledToFill().frame(width:134,height:168).clipped().overlay(RoundedRectangle(cornerRadius:4).stroke(Color.seolin.opacity(0.4),lineWidth:2));Label("얼굴 정렬 · 배경 정리 · 규격 맞춤",systemImage:"sparkles").font(.caption).foregroundStyle(Color.seolin)}.padding(20).accessibilityLabel("자동 맞춤 예시 사진")
                }.frame(height:215)
                VStack(alignment:.leading,spacing:10){Text("사진 규격").font(.subheadline).foregroundStyle(.secondary);Button{settings=true}label:{HStack{VStack(alignment:.leading,spacing:4){Text(store.settings.presetName).font(.headline);Text(store.settings.dimensions).foregroundStyle(.secondary)};Spacer();Image(systemName:"chevron.right").foregroundStyle(.secondary)}.padding(18).background(Color.panel,in:RoundedRectangle(cornerRadius:16)).overlay(RoundedRectangle(cornerRadius:16).stroke(Color.secondary.opacity(0.2)))}.buttonStyle(.plain)
                    Text("\(store.settings.background == "white" ? "흰색" : store.settings.background == "clear" ? "투명" : "원본") 배경 · \(store.settings.orig || store.settings.clear ? "용량 제한 없음" : "최대 \(Int(store.settings.maxkb)) KB")").font(.caption).foregroundStyle(.secondary)}
                ImportActions()
                if !store.ready {HStack{if store.progress != "준비 실패"{ProgressView()};Text(store.progress).font(.caption);if store.progress=="준비 실패"{Button("다시 시도"){Task{await store.prepare()}}}}.frame(maxWidth:.infinity)}
                if !store.photos.isEmpty {Button("작업 중인 사진 \(store.photos.count)장 보기"){store.path=[.batch]}.frame(maxWidth:.infinity)}
                Text("여러 장을 한 번에 선택할 수 있어요").font(.caption).foregroundStyle(.secondary).frame(maxWidth:.infinity)
                Image("SeolinLogo").resizable().scaledToFit().frame(height:42).frame(maxWidth:.infinity).accessibilityLabel("서린태권도")
            }.padding(22).frame(maxWidth:560)
        }.background(Color.panel).toolbar(.hidden,for:.navigationBar)
        .sheet(isPresented:$settings){SettingsView(draft:store.settings)}
    }
}
