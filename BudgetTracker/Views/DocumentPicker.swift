import SwiftUI
import UniformTypeIdentifiers

#if os(iOS)
import UIKit
#endif

#if os(iOS)

struct DocumentPicker: UIViewControllerRepresentable {
    enum PickerType {
        case open, save(Data, String)
    }

    var pickerType: PickerType
    var completion: (URL?) -> Void

    func makeCoordinator() -> Coordinator {
        return Coordinator(completion: completion)
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        switch pickerType {
        case .open:
            let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.json])
            picker.delegate = context.coordinator
            return picker

        case .save(let data, let suggestedName):
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(suggestedName)
            try? data.write(to: tempURL)
            let picker = UIDocumentPickerViewController(forExporting: [tempURL])
            picker.delegate = context.coordinator
            return picker
        }
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let completion: (URL?) -> Void

        init(completion: @escaping (URL?) -> Void) {
            self.completion = completion
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            completion(urls.first)
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            completion(nil)
        }
    }
}

#elseif os(macOS)

struct DocumentPicker: View {
    enum PickerType {
        case open, save(Data, String)
    }

    var pickerType: PickerType
    var completion: (URL?) -> Void

    var body: some View {
        Button("Select File") {
            switch pickerType {
            case .open:
                let panel = NSOpenPanel()
                panel.allowedContentTypes = [.json]
                panel.allowsMultipleSelection = false
                if panel.runModal() == .OK {
                    completion(panel.url)
                } else {
                    completion(nil)
                }

            case .save(let data, let suggestedName):
                let panel = NSSavePanel()
                panel.nameFieldStringValue = suggestedName
                panel.allowedContentTypes = [.json]
                if panel.runModal() == .OK, let url = panel.url {
                    do {
                        try data.write(to: url)
                        completion(url)
                    } catch {
                        print("❌ Failed to write file: \(error)")
                        completion(nil)
                    }
                } else {
                    completion(nil)
                }
            }
        }
    }
}

#endif
