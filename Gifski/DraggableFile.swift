import Cocoa

class DraggableFile: NSImageView, NSDraggingSource, NSFilePromiseProviderDelegate {
	var mouseDownEvent: NSEvent?

	var fileUrl: URL?

	public func filePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider, fileNameForType fileType: String) -> String {
		return fileUrl!.lastPathComponent
	}

	public func filePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider, writePromiseTo url: URL, completionHandler: @escaping (Error?) -> Void) {

		do {
			try FileManager.default.copyItem(at: fileUrl!, to: url)
			completionHandler(nil)
		} catch let error {
			print(error)
			completionHandler(error)
		}
	}

	override init(frame frameRect: NSRect) {
		super.init(frame: frameRect)
		isEditable = true
	}

	required init?(coder: NSCoder) {
		super.init(coder: coder)
		isEditable = true
	}

	override func draw(_ dirtyRect: NSRect) {
		super.draw(dirtyRect)
	}

	func draggingSession(_: NSDraggingSession, sourceOperationMaskFor _: NSDraggingContext) -> NSDragOperation {
		return .copy
	}

	func draggingSession(_: NSDraggingSession, endedAt _: NSPoint, operation: NSDragOperation) {
	}

	override func mouseDown(with theEvent: NSEvent) {
		mouseDownEvent = theEvent
	}

	override func mouseDragged(with event: NSEvent) {
		let mouseDown = mouseDownEvent!.locationInWindow
		let dragPoint = event.locationInWindow
		let dragDistance = hypot(mouseDown.x - dragPoint.x, mouseDown.y - dragPoint.y)

		if dragDistance < 3 {
			return
		}

		guard let image = self.image else {
			return
		}

		let size = NSSize(width: log10(image.size.width) * 30, height: log10(image.size.height) * 30)

		if let draggingImage = image.resize(withSize: size) {
			let draggingItem = NSDraggingItem(pasteboardWriter: NSFilePromiseProvider(fileType: "public.data", delegate: self))
			let draggingFrameOrigin = convert(mouseDown, from: nil)
			let draggingFrame = NSRect(origin: draggingFrameOrigin, size: draggingImage.size)
				.offsetBy(dx: -draggingImage.size.width / 2, dy: -draggingImage.size.height / 2)

			draggingItem.draggingFrame = draggingFrame

			draggingItem.imageComponentsProvider = {
				let component = NSDraggingImageComponent(key: NSDraggingItem.ImageComponentKey.icon)

				component.contents = image
				component.frame = NSRect(origin: NSPoint(), size: draggingFrame.size)
				return [component]
			}

			beginDraggingSession(with: [draggingItem], event: mouseDownEvent!, source: self)
		}
	}
}
