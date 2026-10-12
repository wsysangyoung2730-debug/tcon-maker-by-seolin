import SwiftUI
import UIKit

struct CameraPicker:UIViewControllerRepresentable {
    var onImage:(UIImage)->Void
    @Environment(\.dismiss) private var dismiss
    func makeCoordinator()->Coordinator{Coordinator(self)}
    func makeUIViewController(context:Context)->UIImagePickerController {
        let c=UIImagePickerController();c.sourceType = .camera;c.cameraCaptureMode = .photo;c.delegate=context.coordinator;return c
    }
    func updateUIViewController(_ uiViewController:UIImagePickerController,context:Context){}
    final class Coordinator:NSObject,UIImagePickerControllerDelegate,UINavigationControllerDelegate {
        let parent:CameraPicker;init(_ parent:CameraPicker){self.parent=parent}
        func imagePickerControllerDidCancel(_ picker:UIImagePickerController){parent.dismiss()}
        func imagePickerController(_ picker:UIImagePickerController,didFinishPickingMediaWithInfo info:[UIImagePickerController.InfoKey:Any]){parent.dismiss();if let image=info[.originalImage] as? UIImage{parent.onImage(image)}}
    }
}
struct ShareSheet:UIViewControllerRepresentable {
    let urls:[URL]
    func makeUIViewController(context:Context)->UIActivityViewController {UIActivityViewController(activityItems:urls,applicationActivities:nil)}
    func updateUIViewController(_ uiViewController:UIActivityViewController,context:Context){}
}
struct FilesExporter:UIViewControllerRepresentable {
    let urls:[URL]
    var onFinish:(Bool)->Void
    func makeCoordinator()->Coordinator{Coordinator(onFinish)}
    func makeUIViewController(context:Context)->UIDocumentPickerViewController {
        let picker=UIDocumentPickerViewController(forExporting:urls,asCopy:true);picker.delegate=context.coordinator;return picker
    }
    func updateUIViewController(_ uiViewController:UIDocumentPickerViewController,context:Context){}
    final class Coordinator:NSObject,UIDocumentPickerDelegate {
        let finish:(Bool)->Void;init(_ finish:@escaping(Bool)->Void){self.finish=finish}
        func documentPickerWasCancelled(_ controller:UIDocumentPickerViewController){finish(false)}
        func documentPicker(_ controller:UIDocumentPickerViewController,didPickDocumentsAt urls:[URL]){finish(!urls.isEmpty)}
    }
}
