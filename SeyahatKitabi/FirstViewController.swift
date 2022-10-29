//
//  FirstViewController.swift
//  SeyahatKitabi
//
//  Created by Berke Topcu on 29.10.2022.
//

import UIKit

class FirstViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        // Do any additional setup after loading the view.
        navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.add, target: self, action: #selector(addClicked))
        
    }
    

    // Table View üzerinde kaç satır görünecek
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    //Table View satırlarında hangi veri görünecek
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        var content = cell.defaultContentConfiguration()
        content.text = "Test"
        cell.contentConfiguration = content
        return cell
    }
    //TopBar butonu kullanıldığında segue ile diğer VC'ye geçip pin kaydetme işlemi gerçekletirmek için segue
    @objc func addClicked () {
        performSegue(withIdentifier: "toDetailVC", sender: nil)
    }
    //Segue için hazırlık, Id'si şu olan segue'nin VC'si budur.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toDetailVC" {
            let destinationVC = segue.destination as! ViewController
        }
    }
}
