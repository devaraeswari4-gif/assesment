import UIKit

final class HomeViewController: UIViewController {

    private let titleLabel = UILabel()
    private let scanButton = UIButton(type: .system)
    private let historyButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "QR Scanner"
        navigationController?.navigationBar.prefersLargeTitles = true
        setupUI()
    }

    private func setupUI() {
        titleLabel.text = "Product Verification"
        titleLabel.font = .boldSystemFont(ofSize: 22)
        titleLabel.textAlignment = .center

        scanButton.setTitle("Scan QR Code", for: .normal)
        scanButton.titleLabel?.font = .boldSystemFont(ofSize: 18)
        scanButton.addTarget(self, action: #selector(openScanner), for: .touchUpInside)

        historyButton.setTitle("View History", for: .normal)
        historyButton.addTarget(self, action: #selector(openHistory), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [titleLabel, scanButton, historyButton])
        stack.axis = .vertical
        stack.spacing = 24
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24)
        ])
    }

    @objc private func openScanner() {
        navigationController?.pushViewController(ScannerViewController(), animated: true)
    }

    @objc private func openHistory() {
        navigationController?.pushViewController(HistoryViewController(), animated: true)
    }
}
