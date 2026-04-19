import UIKit

final class HistoryViewController: UITableViewController {

    private var data: [ScanRecord] = []
    private var filtered: [ScanRecord] = []

    private lazy var dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    private let filterSegment = UISegmentedControl(items: ["All", "Genuine", "Unverified"])

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "History"
        setupFilterHeader()
        setupSearch()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutTableHeader()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        data = StorageManager.shared.fetch().reversed()
        applyFilter()
    }

    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        filtered.count
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        let item = filtered[indexPath.row]

        cell.textLabel?.text = item.name
        cell.textLabel?.numberOfLines = 2

        let statusText = item.status ? "Genuine" : "Unverified"
        let when = dateFormatter.string(from: item.date)
        cell.detailTextLabel?.text = "\(statusText) · \(when)"
        cell.detailTextLabel?.textColor = item.status ? .systemGreen : .systemRed
        cell.detailTextLabel?.numberOfLines = 2

        cell.accessibilityLabel = "\(item.name). \(statusText). Scanned \(when)."

        return cell
    }

    override func tableView(_ tableView: UITableView,
                            commit editingStyle: UITableViewCell.EditingStyle,
                            forRowAt indexPath: IndexPath) {

        guard editingStyle == .delete else { return }
        let record = filtered[indexPath.row]
        StorageManager.shared.delete(id: record.id)
        data.removeAll { $0.id == record.id }
        applyFilter()
    }

    private func setupFilterHeader() {
        filterSegment.selectedSegmentIndex = 0
        filterSegment.addTarget(self, action: #selector(filterChanged), for: .valueChanged)

        let container = UIView()
        container.addSubview(filterSegment)
        filterSegment.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            filterSegment.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            filterSegment.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            filterSegment.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            filterSegment.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8)
        ])
        tableView.tableHeaderView = container
    }

    private func layoutTableHeader() {
        guard let header = tableView.tableHeaderView else { return }
        let target = CGSize(width: tableView.bounds.width, height: UIView.layoutFittingCompressedSize.height)
        let height = header.systemLayoutSizeFitting(target).height
        if header.frame.height != height {
            header.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: height)
            tableView.tableHeaderView = header
        }
    }

    private func setupSearch() {
        let search = UISearchController(searchResultsController: nil)
        search.obscuresBackgroundDuringPresentation = false
        search.searchResultsUpdater = self
        navigationItem.searchController = search
    }

    @objc private func filterChanged() {
        applyFilter()
    }

    private func applyFilter() {
        let text = navigationItem.searchController?.searchBar.text ?? ""
        let nameFiltered: [ScanRecord] = text.isEmpty
            ? data
            : data.filter { $0.name.lowercased().contains(text.lowercased()) }

        switch filterSegment.selectedSegmentIndex {
        case 1:
            filtered = nameFiltered.filter(\.status)
        case 2:
            filtered = nameFiltered.filter { !$0.status }
        default:
            filtered = nameFiltered
        }
        tableView.reloadData()
    }
}

extension HistoryViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        applyFilter()
    }
}
