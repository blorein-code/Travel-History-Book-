//
//  FirstViewController.swift
//  SeyahatKitabi
//
//  Created by Berke Topcu on 29.10.2022.
//

import UIKit
import CoreData

class FirstViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {
    @IBOutlet weak var tableView: UITableView!
    var nameArray = [String]()
    var idArray = [UUID]()
    var selectedName = ""
    var selectedId : UUID?
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        //Table View üzerindeki + butonu oluşturuldu
        navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.add, target: self, action: #selector(addClicked))
        //veri çekme fonksiyonumuzun çalışması için viewdidload altında çağırdık.
        getData()
    }
    //Her görünüm göründüğünde çağrılması için willappear fonksiyonunda gerçekleştirdik. Eğer viewDidLoad içinde yapsaydık bir kere gerçekleşirdi.
    override func viewWillAppear(_ animated: Bool) {
        //Bir gözlemci ekleyip, gözlemcinin bu view controller oldugunu belirttik. Hangi işlem yapıldığında gözlemlensin  kısmını Veriler çekildiğinde yani (getData) çalıştığında olsun dedik ve notification.name diğer view controllerdaki isimle aynı olmalı dedik.
        NotificationCenter.default.addObserver(self, selector: #selector(getData), name: NSNotification.Name("newPlace"), object: nil)
    }
    
   @objc func getData () {
       let appDelegate = UIApplication.shared.delegate as! AppDelegate
       let context = appDelegate.persistentContainer.viewContext
       let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Travels")
       fetchRequest.returnsObjectsAsFaults = false
       
       do {
           let results = try context.fetch(fetchRequest)
           
           if results.count > 0 {
               //her eklenende bir öncekini tutmayıp listeyi temizleyip sıfırdan çağırması için
               self.nameArray.removeAll(keepingCapacity: false)
               self.idArray.removeAll(keepingCapacity: false)
               //results'ı dönüp her bir veriyi result olarak aldık. Daha sonra aldığım verilere if let kontrolü yaparak scope'ta tanımladığımız arrayler'e append ettik.
               for result in results as! [NSManagedObject] {
                   if let name = result.value(forKey: "travelName") as? String {
                       nameArray.append(name)
                   }
                   if let id = result.value(forKey: "id") as? UUID {
                       idArray.append(id)
                   }
                   tableView.reloadData()
               }
           }
           
       } catch {
           print("There is an Error Occured from getData")
       }
       
    }
    

    // Table View üzerinde kaç satır görünecek
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return nameArray.count
    }
    //Table View satırlarında hangi veri görünecek
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        var content = cell.defaultContentConfiguration()
        content.text = nameArray[indexPath.row]
        cell.contentConfiguration = content
        return cell
    }
    //TopBar butonu kullanıldığında segue ile diğer VC'ye geçip pin kaydetme işlemi gerçekletirmek için segue
    @objc func addClicked () {
        selectedName = ""
        performSegue(withIdentifier: "toDetailVC", sender: nil)
    }
    //Segue için hazırlık, Id'si şu olan segue'nin VC'si budur.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toDetailVC" {
            let destinationVC = segue.destination as! ViewController
            destinationVC.chosenName = selectedName
            destinationVC.chosenID = selectedId
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedName = nameArray[indexPath.row]
        selectedId = idArray[indexPath.row]
        performSegue(withIdentifier: "toDetailVC", sender: nil)
    }
    
    //uygulamadan ve CoreData üzerinden silme işlemlerini gerçekleştirdik. Kursun içerisinde yoktu kendim ekledim.
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Travels")
            fetchRequest.returnsObjectsAsFaults = false
            
            do {
                //Tekrar fetchRequest işlemleri ile Core Data üzerinden ilgili Entity'e ulaşıp verileri aldık daha sonra context.fetch işlemini gerçekleştirdik ve gelen veri var mı kontrolü yaptık. if let kontrolü ile "id" adında yeni bir değişken oluşturup gelen veride tipi UUID ve ismi id olan bir veri varsa ekranda tıklanan satırdaki id'yi veritabanından sildik ve bu satırdaki Name'i sildik. Daha sonrasında güncel verileri görmek için tableView.reloadData diyerek CoreData'da bulunan güncel verileri tekrar ekrana getirdik.
                
                let results = try context.fetch(fetchRequest)
                if results.count > 0 {
                    for result in results as! [NSManagedObject]{
                        if let id = result.value(forKey: "id") as? UUID {
                            
                            if id == idArray[indexPath.row] {
                                //gelen sonuçlardan tıklanan satırdaki id'yi sildik
                                context.delete(result)
                                //tıklanan satırdaki name'i sildik
                                nameArray.remove(at: indexPath.row)
                                
                                self.tableView.reloadData()
                                
                                do {
                                    //tekrar coreData'ya güncel halini kaydettik.
                                    try context.save()
                                } catch {
                                    print("hata var burda")
                                }
                                break
                            }
                        }
                    }
                }
            } catch {
                print("Problem occured while deleting. ")
            }
            
        }
    }
    
}
