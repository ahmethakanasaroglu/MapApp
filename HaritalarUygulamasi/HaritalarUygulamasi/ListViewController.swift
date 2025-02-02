//
//  ListViewController.swift
//  HaritalarUygulamasi
//
//  Created by Ahmet Hakan Asaroğlu on 11.01.2025.
//

import UIKit
import CoreData

class ListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    var isimDizisi = [String]()
    var idDizisi = [UUID]()
    
    var secilenYerIsmi = ""
    var secilenYerId : UUID?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        tableView.delegate = self
        tableView.dataSource = self
        
        navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.add, target: self, action: #selector(artiButtonuTiklandi)) // sağ üstte eklemek için + gözükmesini yaptık.
        
        veriAl()
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(veriAl), name: NSNotification.Name("yeniYerOlusturuldu"), object: nil)  // view gelince yeniYerOlusturuldu görünce olan
    } // yeniYerOlusturuldu mesajı alınca ne yapacagını verdik, veriAl fonksiyonunu gerceklestirir
    
    
    
    @objc func veriAl() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Yer")
        request.returnsObjectsAsFaults = false
        
        do {
            let sonuclar = try context.fetch(request) // contexti yakalamayı try edicek burada
            
            if sonuclar.count > 0 {  // yani gelen bir sonuc varsa boş degilse dönen deger
                
                isimDizisi.removeAll(keepingCapacity: false)
                idDizisi.removeAll(keepingCapacity: false) // dizileri boşalttık döngüye girerken birden fazla tutmasın diye, kapasiteyi boşaltsın diye de false atadık
                
                for sonuc in sonuclar as! [NSManagedObject] {
                    if let isim = sonuc.value(forKey: "isim") as? String {
                        isimDizisi.append(isim)
                    }
                    
                    if let id = sonuc.value(forKey: "id") as? UUID {
                        idDizisi.append(id)
                    }
                    
                }
                
                tableView.reloadData()  // tableView' ımızı yeniliyoruz data geldikce
                
            }
            
        } catch {
            print("hata var")
        }
        
        
    }
    
    
    
    @objc func artiButtonuTiklandi () { // tıklanınca + ya perform segue yapıcaz
        secilenYerIsmi = ""
        performSegue(withIdentifier: "toMapsVC", sender: nil)
        
        
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isimDizisi.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = isimDizisi[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        secilenYerIsmi = isimDizisi[indexPath.row]
        secilenYerId = idDizisi[indexPath.row]
        
        performSegue(withIdentifier: "toMapsVC", sender: nil)
    } // table view'da herhangi bir row'a tıklanınca ne yapacagız
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toMapsVC" {
            let destinationVC = segue.destination as! MapsViewController
            destinationVC.secilenIsim = secilenYerIsmi
            destinationVC.secilenId = secilenYerId
        }
    } // row'a tıklayınca segue yapmak lazım, segue hazırla diyoruz: prepare for segue
    
    

}
