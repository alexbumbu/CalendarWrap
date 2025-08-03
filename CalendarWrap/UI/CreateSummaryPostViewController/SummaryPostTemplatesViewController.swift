//
//  SummaryPostTemplatesViewController.swift
//  CalendarWrap
//
//  Created by Alex Bumbu on 24.04.2024.
//

import UIKit
import OSLog

private typealias DataSource = UITableViewDiffableDataSource<Int, SummaryTemplate>

class SummaryPostTemplatesViewController: UIViewController {
    
    private enum Constants {
        static let templateCellIdentifier = "templateCell"
    }
    
    @IBOutlet private weak var tableView: UITableView!
    
    var didSelectTemplate: ((SummaryTemplate) -> Void)?
        
    private var templates: [SummaryTemplate] = .init()
    private var selectedTemplate: SummaryTemplate?

    private var dataSource: DataSource!
    
    required init?(selectedTemplate: SummaryTemplate?, coder: NSCoder) {
        super.init(coder: coder)
        
        loadSummaryTemplates()
        self.selectedTemplate = selectedTemplate
    }
    
    @available(*, unavailable, renamed: "init(selectedTemplate:coder:)")
    required init?(coder: NSCoder) {
        fatalError("Invalid way of decoding this class")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
                
        setupDataSource()
        loadDataSource()
    }
}

extension SummaryPostTemplatesViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let template = templates[indexPath.row]
        guard template != selectedTemplate else {
            return
        }
        
        didSelectTemplate?(template)

        // refresh UI
        var itemsToReload = [SummaryTemplate]()
        // for the reloading to work NSDiffableDataSourceSnapshot requires using the same instance as the displayed object
        if let selectedTemplate = templates.first(where: { $0 == selectedTemplate}) {
            itemsToReload.append(selectedTemplate)
        }
        
        selectedTemplate = template        
        itemsToReload.append(template)
        
        var snapshot = dataSource.snapshot()
        snapshot.reloadItems(itemsToReload)
        
        dataSource.apply(snapshot)
    }
}

private extension SummaryPostTemplatesViewController {
    
    func loadSummaryTemplates() {
        if let fileURL = Bundle.main.url(forResource: "SummaryTemplates", withExtension: "plist") {
            do {
                let decoder = PropertyListDecoder()
                
                let data = try Data(contentsOf: fileURL)
                templates = try decoder.decode([SummaryTemplate].self, from: data)
            } catch {
                Logger.ui.debug("decoding SummaryTemplates failure: \(error)")
            }
        }
        
        templates.insert(SummaryTemplate.empty(), at: 0)
    }

    func setupDataSource() {
        dataSource = DataSource(tableView: tableView, cellProvider: { [weak self] tableView, indexPath, template in
            let cell = tableView.dequeueReusableCell(withIdentifier: Constants.templateCellIdentifier) as? PostTemplateCell
            cell?.titleLabel.text = template.name
            cell?.accessoryType = template == self?.selectedTemplate ? .checkmark : .none
            
            return cell
        })
    }
    
    func loadDataSource() {
        var updatesSnapshot = NSDiffableDataSourceSnapshot<Int, SummaryTemplate>()
        updatesSnapshot.appendSections([0])
        updatesSnapshot.appendItems(templates)
        
        dataSource.apply(updatesSnapshot, animatingDifferences: true)
    }
    
}
