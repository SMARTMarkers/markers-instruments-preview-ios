//
//  MasterViewController.swift
//  SMARTMarkers Instruments
//
//  Created by Raheel Sayeed on 7/25/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import UIKit
import SMARTMarkers
import SMART
import HealthKit

class MasterViewController: UITableViewController {


    var taskController: TaskController?
    var sessionController: SessionController?
    var instruments = [Instrument]()
    var patient: Patient? {
        didSet {
            DispatchQueue.main.async {
                self.btnPatientSelector?.title = self.patient?.humanName
            }
        }
    }
    let sessionBtn = UIBarButtonItem(title: "Start Session", style: .plain, target: self, action: #selector(startSession(_:)))
    var btnPatientSelector: UIBarButtonItem?
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        Patient.read("b85d7e00-3690-4e2a-87a0-f3d2dfc908b3", server: Server.Demo()) { [weak self] (p, e) in
            self?.patient = (p as! Patient)
        }
        
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.isEditing = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Start Session", style: .plain, target: self, action: #selector(startSession(_:)))
        btnPatientSelector = UIBarButtonItem(title: "Select Patient", style: .plain, target: self, action: #selector(selectPatient(_:)))
        navigationItem.leftBarButtonItem = btnPatientSelector
        
        if let q = localQuestionnaire("promis_q_dynamic") {
            instruments.append(q)
        }
        
        if let q = localQuestionnaire("bmi_r4") {
            instruments.append(q)
        }
        if let q = localQuestionnaire("dynamicquestionnaire") {
            instruments.append(q)
        }
        if let q = localQuestionnaire("dynamicquestionnaire_valuecoding") {
            instruments.append(q)
        }
        
        
        instruments.append(contentsOf: SMARTMarkers.Instruments.ActiveTasks.allCases.map { $0.instance })
        instruments.append(contentsOf: SMARTMarkers.Instruments.HealthKit.allCases.map { $0.instance })
        tableView.reloadData()
    }
    
    


    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return instruments.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        cell.accessoryType = .detailDisclosureButton
        cell.editingAccessoryType = .detailDisclosureButton
        let instrument = instruments[indexPath.row]
        cell.textLabel!.text = instrument.sm_title
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    
    func startMeasure(_ controller: TaskController) {
        
        taskController = controller

        taskController?.prepareSession(callback: { (task, error) in
            if let controller = task {
                self.present(controller, animated: true, completion: nil)
            }
        })
        
        taskController?.onTaskCompletion = { [unowned self] submissionBundle, error in
            
            submissionBundle?.canSubmit = true
            
            if let reports = self.taskController?.reports {
                reports.submit(to: Server.Demo(), patient: self.patient!, callback: { (success, error) in
                    print("submission")
                    print("==================")
                    print(success)
                    print(error as Any)
                    print(reports.reports)
                })
            }
        }
    }
    

    @objc func startSession(_ sender: Any?) {
        
        guard let tasks = tableView.indexPathsForSelectedRows?.map ({ TaskController(instrument: instruments[$0.row]) }) else {
            return
        }
        
        createSession(tasks)
    }
    
    func createSession(_ tasks: [TaskController]) {
        
        sessionController = SessionController(tasks, patient: patient, server: Server.Demo(), verifyUser: false)
        
        sessionController?.prepareController(callback: { (controller, error) in
            if let controller = controller {
                self.present(controller, animated: true, completion: nil)
            }
        })
        
        sessionController?.onConclusion = { session in
            print(session.identifier)
        }
    }
    
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        
        let instrument = instruments[indexPath.row]
        let viewController = InstrumentViewController(instrument)
        show(viewController, sender: nil)
    }
    
    

    
    
    
    
    func localQuestionnaire(_ filename: String) -> Questionnaire? {
        
        let bundle = Bundle(identifier: "org.chip.SMARTMarkers")
        if let filePath = bundle!.path(forResource: filename, ofType: "json"),
            let data = NSData(contentsOfFile: filePath) {
            do {
                
                // here you have your json parsed as string:
                //let jsonString = try? String(contentsOfFile: filePath, encoding: String.Encoding.utf8)
                
                // but it is better to use the type data instead:
                let jsonData = try JSONSerialization.jsonObject(with: data as Data, options: JSONSerialization.ReadingOptions.allowFragments)
                let q = try Questionnaire(json: jsonData as! FHIRJSON)
                return q
            }
            catch {
                print(error)
            }
            
        }
        return nil
    }


}



extension MasterViewController: InstrumentResolver {
    
    func resolveInstrument(in controller: TaskController, callback: @escaping ((Instrument?, Error?) -> Void)) {
        callback(nil,nil)
    }
    
}


// Patient Selection

extension MasterViewController {
    
    @objc func selectPatient(_ sender: Any?) {
        
        let patientSelect = PatientListAll()
        let patientSelectView = PatientListViewController(list: patientSelect, server: Server.Demo())
        patientSelectView.onPatientSelect = { (patient) in
            self.patient = patient
        }
        self.present(patientSelectView, animated: true, completion: nil)
        
    }
}
