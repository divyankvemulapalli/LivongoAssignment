//
//  HomeViewController.swift
//  BasicStepsHistroy
//
//  Created by Divyank Vemulapalli on 11/9/19.
//  Copyright © 2019 Divyank Vemulapalli. All rights reserved.
//

import Foundation

import UIKit
import HealthKit


// Custon table cell
class StepTableViewCell: UITableViewCell{
    
    var stepCount : UILabel!
    var stepDay : UILabel!
    
    
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:)")
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        
        
        let marginGuide = contentView.layoutMarginsGuide
        
        stepDay = UILabel()
               
        stepDay.font =  .systemFont(ofSize: 15)
               
        stepDay.text = ""
               
        stepDay.textAlignment = .left
               
               
        contentView.addSubview(stepDay)
        
        stepCount = UILabel()
        
        stepCount.text = ""
        
        stepCount.textAlignment = .right
        
        contentView.addSubview(stepCount)
        
        
        stepCount.translatesAutoresizingMaskIntoConstraints = false
        
        stepDay.translatesAutoresizingMaskIntoConstraints = false
        
        
        
        stepDay.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        stepDay.widthAnchor.constraint(equalToConstant: 300).isActive = true
        
        stepDay.centerYAnchor.constraint(equalTo: marginGuide.centerYAnchor).isActive = true
        
        stepDay.leftAnchor.constraint(equalTo: marginGuide.leftAnchor, constant: 20).isActive = true
        
        stepCount.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        stepCount.widthAnchor.constraint(equalToConstant: 300).isActive = true
        
        stepCount.centerYAnchor.constraint(equalTo: marginGuide.centerYAnchor).isActive = true
        
        stepCount.leftAnchor.constraint(equalTo: marginGuide.leftAnchor, constant: 20).isActive = true
        
    
        
    }
    

}

class HomeViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
   
    
   
    @IBOutlet weak var alertNoData: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    private let healthKitManager = HealthKitManager.sharedInstance

    var steps = [HKStatistics]()
    
    private let refreshControl = UIRefreshControl()
    
    private var myTableView: UITableView!
    
    private let dateFormatter: DateFormatter = {
           let formatter = DateFormatter()
           formatter.dateStyle = .long
           return formatter
           }()

    override func viewDidAppear(_ animated: Bool) {
        

        // checking the health access from the user
       let preferences = UserDefaults.standard
       let healthAccessKey = "healthAccess"
       if (preferences.object(forKey: healthAccessKey) == nil) {
        
        let alert = UIAlertController(title: "Usage Alert", message: "The app needs assess to your health information. Please click allow to continue.", preferredStyle: UIAlertController.Style.alert)
           
           
           alert.addAction(UIAlertAction(title: "Allow", style: UIAlertAction.Style.default, handler: { alertAction in
               
                // calling the fuction which enable user to grant access to their health data
                self.requestHealthKitAuthorization()
               self.dismiss(animated: true, completion: nil)
               
           }))
        
        alert.addAction(UIAlertAction(title: "Deny", style: UIAlertAction.Style.default, handler: { alertAction in
            
            self.dismiss(animated: true, completion: nil)
            
            UIControl().sendAction(#selector(NSXPCConnection.suspend),
             to: UIApplication.shared, for: nil)
            
        }))
           
           
           self.present(alert, animated: true, completion: nil)
        
       } else {
        
            // fetching 2 weeks steps histroy
            querySteps()
        
        }
    
              
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        activityIndicator.center = self.view.center
        activityIndicator.hidesWhenStopped = true

        activityIndicator.startAnimating()
        alertNoData.text = ""
        
        let barHeight: CGFloat = UIApplication.shared.statusBarFrame.size.height
        let displayWidth: CGFloat = self.view.frame.width
        let displayHeight: CGFloat = self.view.frame.height
        
        let nav = UINavigationController()
         
        let navigationBarHeight : CGFloat = nav.navigationBar.frame.size.height


        let navigationBar: UINavigationBar = UINavigationBar(frame: CGRect(x: 0, y: barHeight, width: displayWidth, height: navigationBarHeight))
        self.view.addSubview(navigationBar);
        let navigationItem = UINavigationItem(title: "Steps Histroy")
        let toggle = UISwitch()
        toggle.isEnabled = false
        toggle.addTarget(self, action: #selector(toggleValueChanged(_:)), for: .valueChanged)
        let recentLabel = UILabel()
        recentLabel.font = UIFont.boldSystemFont(ofSize: UIFont.smallSystemFontSize)
        recentLabel.text = "Recent"
        let stackView = UIStackView(arrangedSubviews: [recentLabel, toggle])
        stackView.spacing = 8

        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: stackView)
        navigationBar.setItems([navigationItem], animated: false)

       
        
        let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
        
            
            if (self.steps.count > 0)
            {
                self.activityIndicator.stopAnimating()

                       
                self.myTableView = UITableView(frame: CGRect(x: 0, y: navigationBarHeight + barHeight, width: displayWidth, height: displayHeight - 60))
                self.myTableView.register(UITableViewCell.self, forCellReuseIdentifier: "MyCell")
                self.myTableView.dataSource = self
                self.myTableView.delegate = self
                self.myTableView.refreshControl = self.refreshControl
                self.refreshControl.addTarget(self, action: #selector(self.refreshData(_:)), for: .valueChanged)
                self.view.addSubview(self.myTableView)
                
                toggle.isEnabled = true
                timer.invalidate()
            }
            else
            {
                
                let preferences = UserDefaults.standard
                let healthAccessKey = "healthAccess"
                if (preferences.bool(forKey: healthAccessKey) == true)
                {
                    
                    self.activityIndicator.stopAnimating()
                    
                    
                    self.alertNoData.translatesAutoresizingMaskIntoConstraints = false
                    self.alertNoData.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
                    self.alertNoData.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
                    
                    self.alertNoData.textAlignment = .center

                    self.alertNoData.text = "No Data"
                    
                    timer.invalidate()
                }
                

            }
           
        }
             

    }

    @objc func toggleValueChanged(_ toggle: UISwitch) {
        
        self.steps.reverse()
        self.myTableView.reloadData()

    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return steps.count
       }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
                
        return 60
    }
       
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
           
            let cell_temp = StepTableViewCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: String(indexPath.row) )
        
        let step = steps[indexPath.row]
        if let quantity = step.sumQuantity() {
            
            let stepdate = step.startDate
            let value = Int(quantity.doubleValue(for: HKUnit.count()))
           

            cell_temp.stepCount.text = "\(value) steps"
            cell_temp.stepDay.text = dateFormatter.string(from: stepdate)
                  
        }
            return cell_temp
       }
    
    @objc private func refreshData(_ sender: Any) {
        self.refreshControl.endRefreshing()
        myTableView.reloadData()
    }
    
    

}



private extension HomeViewController {
    
    
    // User's Health Data Access
    func requestHealthKitAuthorization() {
        
        let dataTypesToRead = NSSet(objects: healthKitManager.stepsCount as Any)
        healthKitManager.healthStore?.requestAuthorization(toShare: nil, read: dataTypesToRead as? Set<HKObjectType>, completion: { [unowned self] (success, error) in
            if success {
              
                self.querySteps()
                
                let preferences = UserDefaults.standard

                let healthAccess = true
                let healthAccessKey = "healthAccess"
                preferences.set(healthAccess, forKey: healthAccessKey)
                
            
                
            } else {
                
                print(error.debugDescription)
  }
        })
    }
    
    // Fetching steps histroy
    func querySteps() {
        
        
        let calendar = NSCalendar.current
         
        let interval = NSDateComponents()
        interval.day = 1
         
        // Set the anchor date to Monday at 3:00 a.m.
        var anchorComponents = calendar.dateComponents([.day, .month, .year, .weekday], from: NSDate() as Date)
         
         
        let offset = (7 + anchorComponents.weekday! - 2) % 7
        anchorComponents.day! -= offset
        anchorComponents.hour = 3
        
        guard let anchorDate = calendar.date(from: anchorComponents )else {
            fatalError("*** unable to create a valid date from the given components ***")
        }
         

        let query = HKStatisticsCollectionQuery(quantityType:  healthKitManager.stepsCount!,
                    quantitySamplePredicate: nil,
                    options: .cumulativeSum,
                    anchorDate: anchorDate,
                    intervalComponents: interval as DateComponents)
                
        query.initialResultsHandler = {
                   query, results, error in
                   
                   guard let statsCollection = results else {
                       // Perform proper error handling here
                    fatalError("*** An error occurred while calculating the statistics: \(error?.localizedDescription ?? "Error") ***")
                   }
                   
                   let endDate = NSDate()
                   
            guard let startDate = calendar.date(byAdding: .weekOfYear, value: -2, to: endDate as Date)else {
                fatalError("*** Unable to calculate the start date ***")
            }
                   
            statsCollection.enumerateStatistics(from: startDate, to: endDate as Date) { [unowned self] statistics, stop in
                
                 if let quantity = statistics.sumQuantity() {
                           
                           let value = Int(quantity.doubleValue(for: HKUnit.count()))
                          
                    if value > 0{
                        
                        self.steps.append(statistics)
                       }
                }

                   }
               }
                
              healthKitManager.healthStore?.execute(query)
        
    }
    
}


