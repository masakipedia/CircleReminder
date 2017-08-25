//
//  ViewController.swift
//  Reminder5
//
//  Created by MasakiOkuno on 2017/08/17.
//  Copyright © 2017年 mycompany. All rights reserved.
//

import UIKit
import Eureka

class ViewController: FormViewController, UIApplicationDelegate {
    
    // AppDelegateに宣言された変数を使用する
    var appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        form
            +++ Section("やること")
            <<< TextRow("TaskName") {
                $0.title = "課題名"
                $0.value = appDelegate.name
                $0.add(rule: RuleRequired())
                $0.validationOptions = .validatesOnBlur
                }.onChange {
                    self.appDelegate.name = $0.value ?? ""
                }.cellUpdate { cell, row in
                    if !row.isValid {
                        cell.titleLabel?.textColor = .red
                    }
            }
            <<< DateTimeRow("DeadLine") {
                $0.title = "締切日"
                $0.value = appDelegate.deadline
                $0.validationOptions = .validatesOnBlur
                }.onChange {
                    self.appDelegate.deadline = $0.value!
            }
            
            +++ Section("通知設定")
            <<< SwitchRow("switchRowTag"){
                $0.title = (self.appDelegate.notiAccept) ? "通知 ON" : "通知 OFF"
                $0.value = appDelegate.notiAccept
                }.onChange { row in
                    row.title = (row.value ?? false) ? "通知 ON" : "通知 OFF"
                    row.updateCell()
                    self.appDelegate.notiAccept = row.value!
            }
            <<< CountDownRow() {
                $0.hidden = Condition.function(["switchRowTag"], { form in
                return !((form.rowBy(tag: "switchRowTag") as? SwitchRow)?.value ?? false)
            })
                $0.title = "通知する間隔"
                $0.add(rule: RuleRequired())
                $0.value = appDelegate.interval
                $0.validationOptions = .validatesOnBlur
                }.onChange {
                    self.appDelegate.interval = $0.value!
            }
            
            +++ Section("通知内容") {
            $0.hidden = Condition.function(["switchRowTag"], { form in
                    return !((form.rowBy(tag: "switchRowTag") as? SwitchRow)?.value ?? false)
            })}
            <<< LabelRow("textNotiLabelRow"){
                $0.title = "通知メッセージ↓"
            }
            <<< TextAreaRow("textNotiMessageRow"){
                $0.value = appDelegate.notiMessage
                $0.add(rule: RuleRequired())
                $0.validationOptions = .validatesOnBlur
                }.onChange {
                    self.appDelegate.notiMessage = $0.value ?? ""
            }
    }
    
    @IBAction func didTapSaveButton(_ sender: UIBarButtonItem) {
        // 入力漏れのチェック
        let errors = form.validate()
        guard errors.isEmpty else {
            print("validate errors:", errors)
            createAlert(title: "未入力の部分あります", message: "入力してください")
            return
        }
        
        // 締切が過去の場合
        if appDelegate.deadline < Date() {
            print("deadline error")
            createAlert(title: "締切日が過去になっています", message: "締切日を新たに選択してください")
            return
        }
        
        // 通知が許可されている場合
        if appDelegate.notiAccept == true {
            
            // 通知間隔の取得
            appDelegate.hour    = Calendar.current.component(.hour, from: appDelegate.interval)
            appDelegate.minute  = Calendar.current.component(.minute, from: appDelegate.interval)
            
            // 通知タイトルの取得
            appDelegate.notiTitle = "課題名：\(appDelegate.name!)"
            
            // Japanese Locale (ja_JP)
            let dfJST = DateFormatter()
            // 日本時間に設定する
            dfJST.timeZone      = TimeZone(abbreviation: "JST")
            dfJST.dateFormat    = "yyyy/M/d  H:mm"
            
            // 日付の設定をする
            let deadline = String(describing: dfJST.string(from: appDelegate.deadline))
            
            // 通知サブタイトルの取得
            appDelegate.notiSubTitle = "締切　：" + deadline
            
            // データ取得確認
            print("Interval:"       + "\(appDelegate.hour! * 60 + appDelegate.minute!)")
            print("notiTitle: "     + appDelegate.notiTitle!)
            print("notiSubTitle: "  + appDelegate.notiSubTitle!)
            print("notiMessage: "   + appDelegate.notiMessage!)
        }
        
        // データ取得確認
        print("TaskName:"       + appDelegate.name!)
        print("Deadline:"       + "\(appDelegate.deadline)")
        print("Notification: "  + "\(appDelegate.notiAccept)")
        
        
        // 画面遷移
        navigationController!.popViewController(animated: true)
    }
    
    // 入力エラーの警告
    func createAlert (title:String, message:String)
    {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { (action) in
            alert.dismiss(animated: true, completion: nil)
            print ("OK")
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

