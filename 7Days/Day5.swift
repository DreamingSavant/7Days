//
//  Day5.swift
//  7Days
//
//  Created by Roderick Presswood on 6/24/25.
//

import UIKit

class AsyncImageTableViewController: UIViewController {
    struct Item: Hashable {
        let id = UUID()
        let title: String
        let imageURL: URL
    }
    
    enum Section { case main }
    
    private var tableView: UITableView!
    private var dataSource: UITableViewDiffableDataSource<Section, Item>!
    private var cache = NSCache<NSURL, UIImage>()
    private var items: [Item] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupTableView()
        setupDataSource()
        generateItems()
        applySnapshot()
    }
    
    private func setupTableView() {
        tableView = UITableView(frame: view.bounds)
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        view.addSubview(tableView)
    }
    
    private func setupDataSource() {
        dataSource = UITableViewDiffableDataSource<Section, Item>(tableView: tableView) { [weak self] tableView, indexPath, item in
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            cell.textLabel?.text = item.title
            cell.imageView?.image = UIImage(systemName: "photo")
            self?.loadImage(for: item, into: cell)
            return cell
        }
    }
    
    private func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.main])
        snapshot.appendItems(items)
        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    private func generateItems() {
        let urls = [
            "https://via.placeholder.com/100",
            "https://via.placeholder.com/120",
            "https://via.placeholder.com/140",
            "https://via.placeholder.com/160",
            "https://via.placeholder.com/180"
        ].compactMap { URL(string: $0)}
        items = urls.enumerated().map { index, url in
            Item(title: "Image \(index + 1)", imageURL: url)
        }
    }
    
    private func loadImage(for item: Item, into cell: UITableViewCell) {
        if let cachedImage = cache.object(forKey: item.imageURL as NSURL) {
            cell.imageView?.image = cachedImage
            cell.setNeedsLayout()
            return
        }
        DispatchQueue.global().async {
            guard let data = try? Data(contentsOf: item.imageURL), let image = UIImage(data: data) else { return }
            self.cache.setObject(image, forKey: item.imageURL as NSURL)
            
            DispatchQueue.main.async {
                if let currentIndexPath = self.dataSource.indexPath(for: item), let currentCell = self.tableView.cellForRow(at: currentIndexPath) {
                    currentCell.imageView?.image = image
                    currentCell.setNeedsLayout()
                }
            }
        }
    }
}


class ClassicImageTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    struct Item {
        let title: String
        let imageURL: URL
    }
    
    private var tableView: UITableView!
    private var items: [Item] = []
    private var cache = NSCache<NSURL, UIImage>() // NSCache for memory cache
    private let fileManagerQueue = DispatchQueue(label: "com.myapp.fileManagerQueue", attributes: .concurrent) // Concurrent queue for disk cache work
    private let fileManager = FileManager.default
    private let semaphore = DispatchSemaphore(value: 2) // Semaphore to limit concurrent image loads
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupTableView()
        generateItems()
        loadAllImagesWithDispatchGroup() // Example Use of Dispatch group
    }
    
    private func setupTableView() {
        tableView = UITableView(frame: view.bounds)
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        view.addSubview(tableView)
    }
    
    private func generateItems() {
        let urls = [
            "https://via.placeholder.com/100",
            "https://via.placeholder.com/120",
            "https://via.placeholder.com/140",
            "https://via.placeholder.com/160",
            "https://via.placeholder.com/180"
        ].compactMap { URL(string: $0)}
        items = urls.enumerated().map { index, url in
            Item(title: "Image \(index + 1)", imageURL: url)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = item.title
        cell.imageView?.image = UIImage(systemName: "photo")
        
        loadImage(for: item, into: cell, at: indexPath)
        
        return cell
    }
    
    private func loadImage(for item: Item, into cell: UITableViewCell, at indexPath: IndexPath) {
        // check memory cache first
        if let cachedImage = cache.object(forKey: item.imageURL as NSURL) {
            cell.imageView?.image = cachedImage
            cell.setNeedsLayout()
            return
        }
        // Check disk cache (done on fileManagerQueue)
        fileManagerQueue.async {
            let fileURL = self.diskCacheURL(for: item)
            if let data = try? Data(contentsOf: fileURL), let image = UIImage(data: data) {
                self.cache.setObject(image, forKey: item.imageURL as NSURL)
                DispatchQueue.main.async {
                    if let visibleCell = self.tableView.cellForRow(at: indexPath) {
                        visibleCell.imageView?.image = image
                        visibleCell.setNeedsLayout()
                    }
                }
                return
            }
            
            // if not cached, load from network with semaphore limiting concurrency
            self.semaphore.wait()
            let workItem = DispatchWorkItem {
                defer { self.semaphore.signal() }
                guard let data = try? Data(contentsOf: item.imageURL),
                      let image = UIImage(data: data) else { return }
                // Save to disk cache with barrier to ensure safe write
                self.cache.setObject(image, forKey: item.imageURL as NSURL)
                self.fileManagerQueue.async(flags: .barrier) {
                    try? data.write(to: fileURL)
                }
                // Update UI on main thread
                DispatchQueue.main.async {
                    if let visibleCell = self.tableView.cellForRow(at: indexPath) {
                        visibleCell.imageView?.image = image
                        visibleCell.setNeedsLayout()
                    }
                }
            }
            DispatchQueue.global().async(execute: workItem)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("Selected \(items[indexPath.row].title)")
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func diskCacheURL(for item: Item) -> URL {
        let fileName = item.imageURL.lastPathComponent
        return fileManager.temporaryDirectory.appendingPathComponent(fileName)
    }
    
    func loadAllImagesWithDispatchGroup() {
        let group = DispatchGroup()
        for item in items {
            group.enter()
            DispatchQueue.global().async {
                _ = try? Data(contentsOf: item.imageURL)
                print("Finished loading \(item.title)")
                group.leave()
            }
        }
        group.notify(queue: .main) {
            print("All images preloaded with DispatchGroup")
        }
    }
}


class ImageTableViewController: UITableViewController {
    struct Item {
        let title: String
        let url: URL
    }
    
    private var items: [Item] = []
    private let cache = NSCache<NSURL, UIImage>() // In memory cache
    private let fileQueue = DispatchQueue(label: "disk.queue", attributes: .concurrent) // For disk I/O with barrier saftey
    private let semaphore = DispatchSemaphore(value: 2) // Limit concurrent downloads
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadItems()
    }
    
    private func loadItems() {
        // Populate items array with image URLs
        items = [
               Item(title: "Image 1", url: URL(string: "https://via.placeholder.com/100")!),
               Item(title: "Image 2", url: URL(string: "https://via.placeholder.com/120")!),
               Item(title: "Image 3", url: URL(string: "https://via.placeholder.com/140")!)
           ]
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let item = items[indexPath.row]
        cell.textLabel?.text = item.title
        cell.imageView?.image = UIImage(systemName: "photo") // Placeholder image
        loadImage(for: item, into: cell, at: indexPath) // Load actual image async
        return cell
    }
    
    private func loadImage(for item: Item, into cell: UITableViewCell, at indexPath: IndexPath) {
        if let cached = cache.object(forKey: item.url as NSURL) {
            // Use in-memory cache if available
            cell.imageView?.image = cached
            cell.setNeedsLayout()
            return
        }
        
        fileQueue.async {
            // Check disk cache on background queue
            let fileURL = self.diskURL(for: item)
            if let data = try? Data(contentsOf: fileURL), let image = UIImage(data: data) {
                self.cache.setObject(image, forKey: item.url as NSURL)
                DispatchQueue.main.async {
                    // Updatae UI on main thread
                    if let visibleCell = self.tableView.cellForRow(at: indexPath) {
                        visibleCell.imageView?.image = image
                        visibleCell.setNeedsLayout()
                    }
                }
                return
            }
            
            self.semaphore.wait() // Limit concurrent downloads
            let work = DispatchWorkItem {
                defer { self.semaphore.signal()} // Release permit after download
                if let data = try? Data(contentsOf: item.url), let image = UIImage(data: data) {
                    self.cache.setObject(image, forKey: item.url as NSURL) // save to memory cache
                    self.fileQueue.async(flags: .barrier) {
                        try? data.write(to: fileURL) // save to disk cache safely
                    }
                    DispatchQueue.main.async {
                        if let visibleCell = self.tableView.cellForRow(at: indexPath) {
                            visibleCell.imageView?.image = image // Update image on main
                            visibleCell.setNeedsLayout()
                        }
                    }
                    
                }
                    
            }
            DispatchQueue.global().async(execute: work) // Run network fetch
        }
    }
    
    private func diskURL(for item: Item) -> URL {
        // Disk file path for cached image
        FileManager.default.temporaryDirectory.appendingPathComponent(item.url.lastPathComponent)
    }
}
