//
//  ViewController.swift
//  APIWebService
//
//  Created by Michael Dean Villanda on 8/13/20.
//  Copyright © 2020 Michael Dean Villanda. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ViewController: UIViewController {

    lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(table)
        
        NSLayoutConstraint.activate([
            table.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 0),
            table.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            table.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            table.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: 0)
        ])
        
        return table
    }()
    
    var list: BehaviorRelay<[ItemResult]> = BehaviorRelay(value: [])
    
    var disposeBag = DisposeBag()
    
    var cellIdentifier = "cellIdentifier"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setupTableView()
        
        populateData()
    }
    
    func populateData() {
        let success = { (items: ItunesItem) in
            self.list.accept(items.results)
        }
        
        let error = { (error: Error) in
            print("ERROR --- \(error)")
            
            // ALert?
        }
        
        ItunesWebservice.search(offset: 0).request().subscribe(onSuccess: success, onError: error).disposed(by: disposeBag)
    }
    
    func setupTableView() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: self.cellIdentifier)
        
        list.asObservable()
            .bind(to: tableView.rx.items(cellIdentifier: self.cellIdentifier, cellType: UITableViewCell.self)) { (_, item, cell) in
                
                cell.textLabel?.text = item.trackName
                cell.detailTextLabel?.text = item.longDescription
                
        }.disposed(by: disposeBag)
        
        tableView.rx
            .itemSelected
            .subscribe(onNext: { [unowned self] (indexPath) in

                self.tableView.deselectRow(at: indexPath, animated: true)
                
            }).disposed(by: disposeBag)
    }
}

