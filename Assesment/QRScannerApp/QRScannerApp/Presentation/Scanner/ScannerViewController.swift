import UIKit
import AVFoundation

final class ScannerViewController: UIViewController {

    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let overlayView = QRScanFrameOverlayView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        title = "Scan"

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "History",
            style: .plain,
            target: self,
            action: #selector(openHistory)
        )

        #if targetEnvironment(simulator)
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Simulate",
            style: .plain,
            target: self,
            action: #selector(simulateScan)
        )
        #endif

        overlayView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.isUserInteractionEnabled = false
        view.addSubview(overlayView)
        NSLayoutConstraint.activate([
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        checkPermission()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
        let b = overlayView.bounds
        let inset: CGFloat = 48
        let side = max(0, min(b.width, b.height) - inset * 2)
        let x = (b.width - side) / 2
        let y = (b.height - side) / 2
        overlayView.scanRect = CGRect(x: x, y: y, width: side, height: side)
    }

    private func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    granted ? self?.setupCamera() : self?.showPermissionAlert()
                }
            }
        default:
            showPermissionAlert()
        }
    }

    private func showPermissionAlert() {
        let alert = UIAlertController(
            title: "Camera Access Denied",
            message: "Enable camera from Settings to scan QR codes.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func setupCamera() {
        guard let device = AVCaptureDevice.default(for: .video) else {
            showSimulatorUI()
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) { session.addInput(input) }

            let output = AVCaptureMetadataOutput()
            if session.canAddOutput(output) { session.addOutput(output) }

            output.setMetadataObjectsDelegate(self, queue: .main)
            output.metadataObjectTypes = [.qr]

            let preview = AVCaptureVideoPreviewLayer(session: session)
            preview.frame = view.bounds
            preview.videoGravity = .resizeAspectFill
            view.layer.insertSublayer(preview, at: 0)
            self.previewLayer = preview

            session.startRunning()
        } catch {
            print("Camera error:", error)
        }
    }

    private func showSimulatorUI() {
        view.backgroundColor = .white
        let label = UILabel()
        label.text = "Simulator Mode\nUse Simulate Button"
        label.numberOfLines = 0
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    @objc private func simulateScan() {
        let alert = UIAlertController(title: "Enter QR", message: "Paste barcode", preferredStyle: .alert)
        alert.addTextField()
        alert.addAction(UIAlertAction(title: "Scan", style: .default) { _ in
            let value = alert.textFields?.first?.text ?? ""
            self.openProduct(qr: value)
        })
        present(alert, animated: true)
    }

    @objc private func openHistory() {
        navigationController?.pushViewController(HistoryViewController(), animated: true)
    }

    private func openProduct(qr: String) {
        let vc = ProductViewController(qr: qr)
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension ScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {

        guard let obj = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let value = obj.stringValue else { return }

        session.stopRunning()
        openProduct(qr: value)
    }
}

// MARK: - Overlay

private final class QRScanFrameOverlayView: UIView {

    var scanRect: CGRect = .zero {
        didSet { setNeedsDisplay() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
        contentMode = .redraw
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        setNeedsDisplay()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext(), scanRect.width > 0 else { return }

        ctx.setFillColor(UIColor.black.withAlphaComponent(0.45).cgColor)
        ctx.fill(bounds)

        ctx.setBlendMode(.clear)
        ctx.fill(scanRect)

        ctx.setBlendMode(.normal)
        let line: CGFloat = 3
        let len: CGFloat = 28
        let corner = scanRect.insetBy(dx: -line / 2, dy: -line / 2)
        UIColor.white.setStroke()

        func strokeL(_ p1: CGPoint, _ p2: CGPoint) {
            let path = UIBezierPath()
            path.move(to: p1)
            path.addLine(to: p2)
            path.lineWidth = line
            path.lineCapStyle = .round
            path.stroke()
        }

        strokeL(CGPoint(x: corner.minX + len, y: corner.minY), CGPoint(x: corner.minX, y: corner.minY))
        strokeL(CGPoint(x: corner.minX, y: corner.minY), CGPoint(x: corner.minX, y: corner.minY + len))

        strokeL(CGPoint(x: corner.maxX - len, y: corner.minY), CGPoint(x: corner.maxX, y: corner.minY))
        strokeL(CGPoint(x: corner.maxX, y: corner.minY), CGPoint(x: corner.maxX, y: corner.minY + len))

        strokeL(CGPoint(x: corner.minX, y: corner.maxY - len), CGPoint(x: corner.minX, y: corner.maxY))
        strokeL(CGPoint(x: corner.minX + len, y: corner.maxY), CGPoint(x: corner.minX, y: corner.maxY))

        strokeL(CGPoint(x: corner.maxX, y: corner.maxY - len), CGPoint(x: corner.maxX, y: corner.maxY))
        strokeL(CGPoint(x: corner.maxX - len, y: corner.maxY), CGPoint(x: corner.maxX, y: corner.maxY))
    }
}
