//
//  Created by Andrew Podkovyrin
//  Copyright © 2020 Andrew Podkovyrin. All rights reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  https://opensource.org/licenses/MIT
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import UIKit

class FormTableViewController: UITableViewController {
    private(set) var sections: [FormSectionModel]?

    private var cellModelToCellClass: [String: UITableViewCell.Type]

    init(style: UITableView.Style, cellModelToCellClass: [String: UITableViewCell.Type]) {
        self.cellModelToCellClass = cellModelToCellClass

        super.init(style: style)
    }

    @available(*, unavailable)
    override init(style: UITableView.Style) {
        fatalError("init(style:) has not been implemented")
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setSections(_ sections: [FormSectionModel], shouldReload: Bool = true) {
        self.sections = sections

        if shouldReload {
            tableView.reloadData()
        }
    }

    func showInvalidInputForModel(_ model: FormCellModel) {
        if let indexPath = indexPath(for: model), let cell = tableView.cellForRow(at: indexPath) {
            cell.shakeView()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44.0
        tableView.keyboardDismissMode = .onDrag

        for cellDescription in cellModelToCellClass {
            tableView.register(cellDescription.value, forCellReuseIdentifier: cellDescription.key)
        }
    }

    // MARK: Private

    private func indexPath(for model: FormCellModel) -> IndexPath? {
        guard let sections = sections else {
            return nil
        }

        var sectionIndex = 0
        for section in sections {
            if let rowIndex = section.items.firstIndex(where: { $0 === model }) {
                return IndexPath(row: rowIndex, section: sectionIndex)
            }

            sectionIndex += 1
        }

        return nil
    }

    // MARK: UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        sections?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sections = sections else {
            return 0
        }

        let sectionModel = sections[section]

        return sectionModel.items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let sections = sections else {
            preconditionFailure("Invalid state")
        }

        let sectionModel = sections[indexPath.section]
        let items = sectionModel.items

        let item = items[indexPath.row]
        if let textCellModel = item as? TextFieldFormCellModel {
            let reuseIdentifier = String(describing: TextFieldFormCellModel.self)
            let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier,
                                                     for: indexPath) as! TextFieldFormTableViewCell
            cell.model = textCellModel
            cell.delegate = self
            return cell
        }
        else if let segmentedCellModel = item as? SegmentedFormCellModel {
            let reuseIdentifier = String(describing: SegmentedFormCellModel.self)
            let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier,
                                                     for: indexPath) as! SegmentedFormTableViewCell
            cell.model = segmentedCellModel
            return cell
        }
        else if let selectorCellModel = item as? SelectorFormCellModel {
            let reuseIdentifier = String(describing: SelectorFormCellModel.self)
            let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier,
                                                     for: indexPath) as! SelectorFormTableViewCell
            cell.model = selectorCellModel
            return cell
        }
        else if let switcherCellModel = item as? SwitcherFormCellModel {
            let reuseIdentifier = String(describing: SwitcherFormCellModel.self)
            let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier,
                                                     for: indexPath) as! SwitcherFormTableViewCell
            cell.model = switcherCellModel
            return cell
        }
        else {
            preconditionFailure("Unsupported cell model: \(item)")
        }
    }

    // MARK: UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let sections = sections else {
            preconditionFailure("Invalid state")
        }

        guard let cell = tableView.cellForRow(at: indexPath) else {
            return
        }

        let sectionModel = sections[indexPath.section]
        let items = sectionModel.items

        if let selectorCellModel = items[indexPath.row] as? SelectorFormCellModel, selectorCellModel.isEnabled {
            selectorCellModel.action?(cell)
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let sections = sections else {
            preconditionFailure("Invalid state")
        }

        let sectionModel = sections[section]

        return sectionModel.header
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard let sections = sections else {
            preconditionFailure("Invalid state")
        }

        let sectionModel = sections[section]

        return sectionModel.footer
    }
}

extension FormTableViewController: TextFieldFormTableViewCellDelegate {
    func textFieldFormTableViewCellActivateNextFirstResponder(_ cell: TextFieldFormTableViewCell) {
        guard let sections = sections else {
            preconditionFailure("Invalid state")
        }

        guard let indexPath = tableView.indexPath(for: cell), let cellModel = cell.model else {
            return
        }

        assert(cellModel.returnKeyType == .next)

        for section in indexPath.section ..< sections.count {
            let sectionModel = sections[section]
            var row = (indexPath.section == section) ? indexPath.row + 1 : 0
            while row < sectionModel.items.count {
                let cellModel = sectionModel.items[row]
                if cellModel is TextFieldFormCellModel {
                    let indexPath = IndexPath(row: row, section: section)
                    if let cell = tableView.cellForRow(at: indexPath) as? TextFieldFormTableViewCell {
                        cell.textFieldBecomeFirstResponder()
                    }

                    return
                }

                row += 1
            }
        }
    }
}
