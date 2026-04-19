import UIKit

final class ProductViewController: UIViewController {

    private let qr: String
    private let vm = ProductViewModel()

    private let nameLabel = UILabel()
    private let categoryLabel = UILabel()
    private let statusLabel = UILabel()
    private let activity = UIActivityIndicatorView(style: .large)

    init(qr: String) {
        self.qr = qr
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Product"
        setupUI()
        fetch()
    }

    private func setupUI() {
        nameLabel.font = .boldSystemFont(ofSize: 20)
        nameLabel.text = "Loading…"
        categoryLabel.text = " "
        statusLabel.text = " "

        activity.translatesAutoresizingMaskIntoConstraints = false
        activity.hidesWhenStopped = true
        activity.startAnimating()

        let stack = UIStackView(arrangedSubviews: [activity, nameLabel, categoryLabel, statusLabel])
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24)
        ])
    }

    private func fetch() {
        Task {
            do {
                try await vm.load(qr: qr)
                activity.stopAnimating()
                render()
                save()
            } catch {
                activity.stopAnimating()
                showError()
            }
        }
    }

    private func render() {
        guard let p = vm.product else { return }
        nameLabel.text = p.name
        categoryLabel.text = p.category
        statusLabel.text = p.isVerified ? "Genuine" : "Unverified"
        statusLabel.textColor = p.isVerified ? .systemGreen : .systemRed
        statusLabel.font = .boldSystemFont(ofSize: 18)

        statusLabel.accessibilityTraits.insert(.staticText)
        statusLabel.accessibilityLabel = p.isVerified ? "Verification status: Genuine" : "Verification status: Unverified"
    }

    private func showError() {
        nameLabel.text = "—"
        categoryLabel.text = " "
        statusLabel.text = " "
        let alert = UIAlertController(
            title: "Could Not Load Product",
            message: "Check your connection, or try a valid product barcode.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func save() {
        guard let p = vm.product else { return }
        StorageManager.shared.save(
            ScanRecord(name: p.name, status: p.isVerified, date: Date())
        )
    }
}
