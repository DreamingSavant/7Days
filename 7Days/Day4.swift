//
//  Day4.swift
//  7Days
//
//  Created by Roderick Presswood on 6/23/25.
//

import UIKit
import SwiftUI

class DiffiableTableViewController: UIViewController, UITableViewDelegate {
    enum Section {
        case main
    }
    
    struct Item: Hashable {
        let id = UUID()
        let title: String
    }
    
    var item = [Item(title: "Apple"),
        Item(title: "Banana"),
        Item(title: "Cherry"),
        Item(title: "Orange")]
    
    private var tableView: UITableView!
    private var dataSource: UITableViewDiffableDataSource<Section, Item>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView = UITableView(frame: view.bounds)
        view.addSubview(tableView)
        tableView.delegate = self
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        dataSource = UITableViewDiffableDataSource<Section, Item>(tableView: tableView, cellProvider: { [weak self] (tableView, indexPath, itemIdentifier) -> UITableViewCell? in
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            cell.textLabel?.text = self?.item[indexPath.row].title
            return cell
        })
        
        applySnapShot()
    }
    
    private func applySnapShot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.main])
        snapshot.appendItems(item)
        dataSource.apply(snapshot, animatingDifferences: true)
    }
}


class SimpleCollectionViewController: UIViewController {
    enum Section { case main }
    struct Item: Hashable {
        let id = UUID()
        let title: String
    }
    
    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Section, Item>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 100, height: 100)
        
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.backgroundColor = .white
        view.addSubview(collectionView)
        
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
        
        dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) { (collectionView, indexPath, Item) -> UICollectionViewCell? in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
            cell.backgroundColor = .systemBlue
            return cell
        }
        applySnapshot()
    }
    
    private func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.main])
        snapshot.appendItems([
            Item(title: "A"),
            Item(title: "B"),
            Item(title: "C"),
            Item(title: "D")
        ])
        dataSource.apply(snapshot, animatingDifferences: true)
    }
}


class PrefetchTableViewController: UIViewController, UITableViewDataSource, UITableViewDataSourcePrefetching {
    private var tableView: UITableView!
    private var data = Array(1...100).map{ "Item \($0)"}
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView = UITableView(frame: view.bounds)
        tableView.dataSource = self
        tableView.prefetchDataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        view.addSubview(tableView)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = data[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        print("Prefetching rows at: \(indexPaths.map { $0.row })")
    }
}
struct SimpleListView: View {
    let items = ["Apple","Banana", "Cherry"]
    var body: some View {
        List(items, id: \.self) { item in
            Text(item)
        }
    }
}


class FruitsViewController: UIViewController {
    enum Section {case main}
    struct Fruit: Hashable {
        let id = UUID()
        let name: String
    }
    
    private var tableView: UITableView!
    private var dataSource: UITableViewDiffableDataSource<Section, Fruit>!
    private var fruits: [Fruit] = [
        Fruit(name: "Apple"),
        Fruit(name: "Banana"),
        Fruit(name: "Cherry")
    ]
    
    // Simulate loading operations (fake network calls)
    private var loadingOperations: [UUID: Operation] = [:]
    private let queue = OperationQueue()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupTableView()
        setupDataSource()
        applySnapshot(animatingDifferences: false)
        setupNavigationBar()
    }
    
    private func setupTableView() {
        tableView = UITableView(frame: view.bounds)
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.prefetchDataSource = self
        view.addSubview(tableView)
    }
    
    private func setupDataSource() {
        dataSource = UITableViewDiffableDataSource<Section, Fruit>(tableView: tableView) { tableView, indexPath, fruit in
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            cell.textLabel?.text = fruit.name
            return cell
        }
    }
    
    private func applySnapshot(animatingDifferences: Bool = true) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Fruit>()
        snapshot.appendSections([.main])
        snapshot.appendItems(fruits)
        dataSource.apply(snapshot, animatingDifferences: animatingDifferences)
    }
    
    private func setupNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Add", style: .plain, target: self, action: #selector(addFruit))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Remove", style: .plain, target: self, action: #selector(removeFruit))
    }
    
    @objc private func addFruit() {
        let newFruit = Fruit(name: "Fruit \(fruits.count + 1)")
        fruits.append(newFruit)
        applySnapshot()
    }
    
    @objc private func removeFruit() {
        guard !fruits.isEmpty else { return }
        fruits.removeLast()
        applySnapshot()
    }
    
    private func simulateLoad(for fruit: Fruit) {
        guard loadingOperations[fruit.id] == nil else { return }
        let op = BlockOperation {
            Thread.sleep(forTimeInterval: 1.0)
            print("Loaded data for \(fruit.name)")
        }
        loadingOperations[fruit.id] = op
        queue.addOperation(op)
    }
    
    private func cancelLoad(for fruit: Fruit) {
        loadingOperations[fruit.id]?.cancel()
        loadingOperations.removeValue(forKey: fruit.id)
        print("Cancelled loading for \(fruit.name)")
    }
}

extension FruitsViewController: UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        let fruitsToPrefetch = indexPaths.compactMap { dataSource.itemIdentifier(for: $0)}
        for fruit in fruitsToPrefetch {
            simulateLoad(for: fruit)
        }
    }
    
    func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        let fruitsToCancel = indexPaths.compactMap { dataSource.itemIdentifier(for: $0) }
        for fruit in fruitsToCancel {
            cancelLoad(for: fruit)
        }
    }
}
