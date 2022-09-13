//
//  TodoVC.swift
//  CoreDataApp
//
//  Created by Владислав on 12.09.22.
//

import CoreData
import UIKit

final class TodoVC: UITableViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet private weak var searchBar: UISearchBar!
    
    // MARK: - Properties
    var itemsArray = [ItemModel]()
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var getCategory: CategoryModel? {
        didSet {
            title = getCategory?.name
            loadItems()
        }
    }

    // MARK: - Lify cycle

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - IBAction

    @IBAction func addItemBtn(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "Add new item", message: "", preferredStyle: .alert)

        alert.addTextField { textField in
            textField.placeholder = "Your task"
        }

        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        let addAction = UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            if let texField = alert.textFields?.first,
               let text = texField.text,
               text != "",
               let self = self
            {
                let newItem = ItemModel(context: self.context)
                newItem.title = text
                newItem.done = false
                newItem.parentCategory = self.getCategory

                self.itemsArray.append(newItem)
                self.saveItems()
                self.tableView.insertRows(at: [IndexPath(row: self.itemsArray.count - 1, section: 0)], with: .automatic)
            }
        }

        alert.addAction(cancel)
        alert.addAction(addAction)

        present(alert, animated: true)
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        itemsArray.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "todoCell", for: indexPath)
        cell.textLabel?.text = itemsArray[indexPath.row].title
        cell.accessoryType = itemsArray[indexPath.row].done ? .checkmark : .none
        return cell
    }

    // MARK: - Table View Delegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        itemsArray[indexPath.row].done.toggle()
        saveItems()
        tableView.reloadRows(at: [indexPath], with: .fade)
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if let categoryName = getCategory?.name, let itemName = itemsArray[indexPath.row].title {
                let request: NSFetchRequest<ItemModel> = ItemModel.fetchRequest()
                request.predicate = NSPredicate(format: "title MATCHES %@", itemName)

                if let results = try? context.fetch(request) {
                    for object in results {
                        context.delete(object)
                    }
                    itemsArray.remove(at: indexPath.row)
                    saveItems()
                    tableView.deleteRows(at: [indexPath], with: .automatic)
                }
            }
        }
    }

    // MARK: - Core Data

    private func saveItems() {
        do {
            try context.save()
        } catch {
            print("Error save context")
        }
    }

    private func loadItems(with request: NSFetchRequest<ItemModel> = ItemModel.fetchRequest(),
                           predicate: NSPredicate? = nil) {
        guard let name = getCategory?.name else {
            return
        }
        
        let categoryPredicate = NSPredicate(format: "parentCategory.name MATCHES %@", name)
        
        if let predicate = predicate {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, categoryPredicate])
        } else {
            request.predicate = categoryPredicate
        }
        
        do {
            itemsArray = try context.fetch(request)
        } catch {
            print("Error fetch context")
        }
        tableView.reloadData()
    }
}

extension TodoVC: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            loadItems()
            searchBar.resignFirstResponder()
        } else {
            let request: NSFetchRequest<ItemModel> = ItemModel.fetchRequest()
            let searchPredicate = NSPredicate(format: "title CONTAINS %@", searchText)
            request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
            loadItems(with: request, predicate: searchPredicate)
        }
    }
}
