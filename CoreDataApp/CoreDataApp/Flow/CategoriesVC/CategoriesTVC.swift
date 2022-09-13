//
//  CategoriesTVC.swift
//  CoreDataApp
//
//  Created by Владислав on 12.09.22.
//

import CoreData
import UIKit

final class CategoriesTVC: UITableViewController {
    // MARK: - Properties
    
    var categories = [CategoryModel]()

    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadCategories()
    }
    
    // MARK: - IBAction
    
    @IBAction func addCategoryBtn(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "Add new category", message: "", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Category"
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        let addAction = UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            if let texField = alert.textFields?.first,
               let text = texField.text,
               text != "",
               let self = self
            {
                let newCategory = CategoryModel(context: self.context)
                newCategory.name = text
                self.categories.append(newCategory)
                self.saveCategories()
                self.tableView.insertRows(at: [IndexPath(row: self.categories.count - 1, section: 0)], with: .automatic)
            }
        }
        
        alert.addAction(cancel)
        alert.addAction(addAction)
        
        self.present(alert, animated: true)
    }
    
    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        categories.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "categoriesCell", for: indexPath)
        cell.textLabel?.text = categories[indexPath.row].name
        return cell
    }

    // MARK: - Table view delegates
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "goToTodoVC", sender: nil)
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete,
           let name = categories[indexPath.row].name
        {
            let request: NSFetchRequest<CategoryModel> = CategoryModel.fetchRequest()
            request.predicate = NSPredicate(format: "name==\(name)")
            
            if let categories = try? context.fetch(request) {
                for category in categories {
                    context.delete(category)
                }
                
                self.categories.remove(at: indexPath.row)
                saveCategories()
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
        }
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let destination = segue.destination as? TodoVC else { return }
        let selectedIndexPath = tableView.indexPathForSelectedRow
        destination.getCategory = categories[selectedIndexPath!.row]
        
    }

    // MARK: - Core Data
    
    private func saveCategories() {
        do {
            try context.save()
        } catch {
            print("Error save context: \(error)")
        }
    }
    
    private func loadCategories(with request: NSFetchRequest<CategoryModel> = CategoryModel.fetchRequest()) {
        do {
            categories = try context.fetch(request)
        } catch {
            print("Error fetch context")
        }
        tableView.reloadData()
    }
}
