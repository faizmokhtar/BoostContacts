//
//  ContactListViewController.swift
//  BoostContacts
//
//  Created by Faiz Mokhtar on 18/07/2020.
//  Copyright © 2020 Faiz Mokhtar. All rights reserved.
//

import UIKit
import Combine

class ContactListViewController: UIViewController {

    // MARK: - Outlets

    @IBOutlet var tableView: UITableView! {
        didSet {
            let nib = UINib(nibName: "ContactListCell", bundle: nil)
            tableView.register(nib, forCellReuseIdentifier: "ContactListCell")
            tableView.rowHeight = 70
            tableView.delegate = self
            tableView.dataSource = self
        }
    }

    lazy var addButton: UIBarButtonItem = {
        let button = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(didTappedAddButton))
        button.tintColor = .primary
        return button
    }()

    lazy var refreshControl: UIRefreshControl = {
        let control = UIRefreshControl()
        control.attributedTitle = NSAttributedString(string: "Pull to refresh")
        control.addTarget(self, action: #selector(didPullToRefresh), for: .valueChanged)
        return control
    }()

    // MARK: - Properties

    private let viewModel: ContactListViewModel

    private var bindings = Set<AnyCancellable>()

    // MARK: - Inits

    init(viewModel: ContactListViewModel = ContactListViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycles

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Contacts"
        self.navigationItem.rightBarButtonItem = addButton
        self.tableView.addSubview(refreshControl)
        viewModel.getAllContacts()
        setupBindings()
    }

    // MARK: - Actions

    @objc func didTappedAddButton() {
        let viewModel = ContactDetailViewModel()
        let controller = ContactDetailViewController(viewModel: viewModel)
        controller.presentationController?.delegate = self
        let navigation = UINavigationController(rootViewController: controller)
        self.present(navigation, animated: true, completion: nil)
    }

    @objc func didPullToRefresh() {
        viewModel.getAllContacts()
        refreshControl.endRefreshing()
    }

    // MARK: - Methods

    private func setupBindings() {
        viewModel.$contacts
            .receive(on: RunLoop.main)
            .sink(receiveValue: { _ in
                self.tableView.reloadData()
            })
            .store(in: &bindings)
    }
}

// MARK: - ContactListViewController Data Sources

extension ContactListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.contacts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ContactListCell", for: indexPath) as! ContactListCell
        let contact = viewModel.contacts[indexPath.row]
        cell.setup(contact: contact)
        return cell
    }
}

// MARK: - ContactListViewController Delegates

extension ContactListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let contact = viewModel.contacts[indexPath.row]
        let viewModel = ContactDetailViewModel(contact: contact)
        let controller = ContactDetailViewController(viewModel: viewModel)
        controller.presentationController?.delegate = self
        let navigation = UINavigationController(rootViewController: controller)
        self.present(navigation, animated: true, completion: nil)
    }
}

// MARK: - UIAdaptivePresentationController Delegates

extension ContactListViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        viewModel.getAllContacts()
    }
}
