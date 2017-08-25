//
//  TwoHandleViewController.swift
//  CircularSliderExample
//
//  Created by Christopher Olsen on 3/4/16.
//  Copyright © 2016 Christopher Olsen. All rights reserved.
//

import UIKit
import UserNotifications
import CoreData

class TwoHandleViewController: UIViewController {
    @IBOutlet weak var sliderView: UIView!
    @IBOutlet weak var upperHourValueLabel: UILabel!
    @IBOutlet weak var upperMinuteValueLabel: UILabel!
    @IBOutlet weak var lowerHourValueLabel: UILabel!
    @IBOutlet weak var lowerMinuteValueLabel: UILabel!
    @IBOutlet weak var switchAMPM: UISegmentedControl!
    @IBOutlet weak var switchLowAMPM: UISegmentedControl!
    @IBOutlet weak var taskNameLabel: UILabel!
    @IBOutlet weak var intervalHoursLabel: UILabel!
    @IBOutlet weak var intervalMinutesLabel: UILabel!
    @IBOutlet weak var dayLimitLabel: UILabel!
    @IBOutlet weak var hourLimitLabel: UILabel!
    @IBOutlet weak var minuteLimitLabel: UILabel!
    @IBOutlet weak var secondLimitLabel: UILabel!
    
    
    // 午前と午後の計算に使用
    var ampm: Int = 0
    var lowAmpm: Int = 12
    
    // AppDelegateに宣言された変数を使用する
    var appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
    
    
    // 午前と午後の切り替えz動作
    @IBAction func switchLowAmPm(_ sender: Any) {
        if let lowerValue = Int(lowerHourValueLabel.text!) {
            switch switchLowAMPM.selectedSegmentIndex {
            case 0:
                self.lowAmpm = 0
                if lowerValue >= 12 {
                    lowerHourValueLabel.text = "\(lowerValue - 12)"
                }
            case 1:
                self.lowAmpm = 12
                if lowerValue < 12 {
                    lowerHourValueLabel.text = "\(lowerValue + 12)"
                }
            default:
                self.lowAmpm = 0
            }
        }
    }
    
    // 午前と午後の切り替えがさる動作
    @IBAction func switchAmPm(_ sender: Any) {
        if let upperValue = Int(upperHourValueLabel.text!) {
            switch switchAMPM.selectedSegmentIndex {
            case 0:
                self.ampm = 0
                if upperValue >= 12 {
                    upperHourValueLabel.text = "\(upperValue - 12)"
                }
            case 1:
                self.ampm = 12
                if upperValue < 12 {
                    upperHourValueLabel.text = "\(upperValue + 12)"
                }
            default:
                self.ampm = 0
            }
        }
    }
    
    // 画面遷移前に更新してから、表示する
    override func viewWillAppear(_ animated: Bool) {
        
        saveData()
        
    }
    
    func saveData() {
        
        // CoreData
        let context = appDelegate.persistentContainer.viewContext
        let coreData = CoreData(context: context)
        
        // データの代入はここから
        coreData.deadline       = appDelegate.deadline as NSDate
        coreData.interval       = appDelegate.interval as NSDate
        coreData.notiAccept     = appDelegate.notiAccept
        coreData.notiTitle      = appDelegate.notiTitle
        coreData.notiSubTitle   = appDelegate.notiSubTitle
        
        if let value = appDelegate.notiMessage {
            coreData.notiMessage = value
        }
        
        if let value = appDelegate.name {
            taskNameLabel.text = value
            coreData.name      = appDelegate.name
        }
        
        if let _ = appDelegate.hour {
            coreData.hour       = Int64(appDelegate.hour!)
            coreData.minute     = Int64(appDelegate.minute!)
            // 1秒ごとにビューを更新し、残り時間を計算する
            Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(TwoHandleViewController.onUpdateLimit(timer:)), userInfo: nil, repeats: true)
        }
        
        if let value1 = appDelegate.hour, let value2 = appDelegate.minute, appDelegate.notiAccept == true {
            // 通知をする判断
            judgeScheduleNotification()
            
            // intervalごとに通知する
            Timer.scheduledTimer(timeInterval: TimeInterval(value1 * 3600 + value2 * 60), target: self, selector: #selector(TwoHandleViewController.onUpdateNotification(timer:)), userInfo: nil, repeats: true)
        }
        
        appDelegate.saveContext()
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        
        // CoreDataからデータを取ってくる
        getData()
        
        // スライダー作成
        setCircleSlider()
        
        // switchの初期化
        switchLowAMPM.selectedSegmentIndex = 1
    }
    
    func getData() {
        //get the data from core data
        let context = appDelegate.persistentContainer.viewContext
        do {
            let query: NSFetchRequest<CoreData> = CoreData.fetchRequest()
            let results = try context.fetch(query)
            if let value = results.last {
                // データの代入はここから
                appDelegate.name        = value.name
                if let deadline = value.deadline {
                    appDelegate.deadline = deadline as Date
                    appDelegate.interval = value.interval! as Date
                }
                appDelegate.hour        = Int(value.hour)
                appDelegate.minute      = Int(value.minute)
                appDelegate.notiAccept  = value.notiAccept
                appDelegate.notiTitle   = value.notiTitle
                appDelegate.notiSubTitle = value.notiSubTitle
                appDelegate.notiMessage = value.notiMessage
                print("Fetching Complete")
            }
        }
        catch {
            print("Fetching Failed")
        }
    }
    
    func setCircleSlider() {
        // init slider view
        let frame = CGRect(x: 0, y: 0, width: sliderView.frame.width, height: sliderView.frame.height)
        let circularSlider = DoubleHandleCircularSlider(frame: frame)
        
        // setup target to watch for value change
        circularSlider.addTarget(self, action: #selector(TwoHandleViewController.valueChanged(_:)), for: UIControlEvents.valueChanged)
        
        // setup slider defaults
        // NOTE: sliderMaximumAngle must be set before currentValue and upperCurrentValue
        circularSlider.maximumAngle = 360
        circularSlider.unfilledArcLineCap = .round
        circularSlider.filledArcLineCap = .round
        circularSlider.lineWidth = 38
        circularSlider.currentValue = 60
        circularSlider.upperCurrentValue = 80
        
        // add to view
        sliderView.addSubview(circularSlider)
        
        // create and set a transform to rotate the arc so the white space is centered at the bottom
        circularSlider.transform = circularSlider.getRotationalTransform()

    }

    func valueChanged(_ slider: DoubleHandleCircularSlider) {
        let (startHour, startMinute, endHour, endMinute) = calcTime(slider)
        upperHourValueLabel.text    = String(format: "%02d", startHour)
        upperMinuteValueLabel.text  = String(format: "%02d", startMinute)
        lowerHourValueLabel.text    = String(format: "%02d", endHour)
        lowerMinuteValueLabel.text  = String(format: "%02d", endMinute)
    }
    
    func calcTime(_ slider: DoubleHandleCircularSlider) -> (startHour: Int, startMinute: Int, endHour: Int, endMinute: Int) {
        // 開始時間の処理
        let currentValue        = slider.currentValue
        let startHour           = self.ampm + Int(floor(12 * currentValue / 100))
        let startMinuteDouble   = 60 * (currentValue / 10 - Float(floor(currentValue / 10)))
        // 四捨五入して10分ごとにする
        var startMinute = Int(floor(startMinuteDouble / 10) * 10)
        if startMinute == 60 {
            startMinute = 0
        }
        
        // 終了時間の処理
        let upperCurrentValue   = slider.upperCurrentValue
        let endHour             = self.lowAmpm + Int(floor(12 * upperCurrentValue / 100))
        let endMinuteDouble     = 60 * (upperCurrentValue / 10 - Float(floor(upperCurrentValue / 10)))
        // 四捨五入して10分ごとにする
        var endMinute = Int(floor(endMinuteDouble / 10) * 10)
        if endMinute == 60 {
            endMinute = 0
        }
        return (startHour, startMinute, endHour, endMinute)
    }
    
    
    
    // 残り時間を表示する
    // TimerのtimeIntervalで指定された秒数毎に呼び出されるメソッド
    func onUpdateLimit(timer : Timer){
        // 残り時間の計算
        let (days, hours, minutes, seconds) = calcRemainTime(from: Date(), to: appDelegate.deadline)
        
        // ラベルに表示
        dayLimitLabel.text      = "\(days!)"
        hourLimitLabel.text     = "\(hours!)"
        minuteLimitLabel.text   = "\(minutes!)"
        secondLimitLabel.text   = "\(seconds!)"

        
        // 時間に達した場合timerを破棄
        if days == 0 && hours == 0 && minutes == 0 && seconds == 0 {
            timer.invalidate()
        }
    }
    
    // 通知する
    // TimerのtimeIntervalで指定された秒数毎に呼び出されるメソッド
    func onUpdateNotification(timer : Timer){
        if appDelegate.notiAccept == true && (Int(dayLimitLabel.text!) != 0 || Int(hourLimitLabel.text!) != 0 || Int(minuteLimitLabel.text!) != 0) {
            judgeScheduleNotification()
        }
        else {
            timer.invalidate()
            print("notification cancelled")
        }
    }
    
    // 通知可能時間か判断して、通知をセットする
    func judgeScheduleNotification() {
        let date        = Date()
        let nowTime     = Calendar.current.component(.hour, from: date) * 60 + Calendar.current.component(.minute, from: date)
        let upperTime   = Int(upperHourValueLabel.text!)! * 60 + Int(upperMinuteValueLabel.text!)!
        let lowerTime   = Int(lowerHourValueLabel.text!)! * 60 + Int(lowerMinuteValueLabel.text!)!
        if nowTime > upperTime && nowTime < lowerTime {
            scheduleNotification(timeInterval: appDelegate.hour! * 3600 + appDelegate.minute! * 60)
            print("notification scheduled")
        }
        else {
            print("Now Off Hours")
        }
    }
    
    // 残り日時間の計算
    func calcRemainTime(from: Date, to: Date) -> (days: Int?, hours: Int?, minutes: Int?, seconds: Int?) {
        let calendar    = Calendar.current
        let s           = calendar.dateComponents([.second], from: from, to: to).second! - 20
        let days        = Int(s / 86400)
        let hours       = Int((s - days * 86400) / 3600)
        let minutes     = Int(((s - days * 86400 - hours * 3600)) / 60)
        let seconds     = s - (minutes * 60) - (hours * 3600) - (days * 86400)
        return (days, hours, minutes, seconds)
    }

    
    /*
     *  通知機能はここから実装
     */
    func scheduleNotification(timeInterval: Int) {
        let timedNotificationIdentifier = "timedNotificationIdentifier"
        let timerGraphicAttachmentIdentifier = "timerGraphicAttachmentIdentifier"
        
        // 表示内容
        let content         = UNMutableNotificationContent()
        content.title       = appDelegate.notiTitle!
        content.subtitle    = appDelegate.notiSubTitle!
        content.body        = appDelegate.notiMessage!
        content.sound       = .default()
        
        // 表示する画像
        let imageIconURL = Bundle.main.url(forResource: "Clock", withExtension: "gif")!
        let imageAttachment     = try! UNNotificationAttachment(identifier: timerGraphicAttachmentIdentifier, url: imageIconURL, options: nil)
        content.attachments.append(imageAttachment)
        
        let trigger             = UNTimeIntervalNotificationTrigger(timeInterval: Double(timeInterval), repeats: false)
        let notificationRequest = UNNotificationRequest(identifier: timedNotificationIdentifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(notificationRequest, withCompletionHandler: nil)
    }
}
