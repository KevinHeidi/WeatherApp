//
//  ViewController.swift
//  swift Weather
//
//  Created by Kevin.L on 17/3/15.
//  Copyright (c) 2015年 Kevin.L. All rights reserved.
//

import UIKit
import CoreLocation

class ViewController: UIViewController,CLLocationManagerDelegate {
    
    @IBOutlet weak var location: UILabel!
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var temperature: UILabel!
    @IBOutlet weak var loading: UILabel!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    let locationManger:CLLocationManager =
        CLLocationManager()

    override func viewDidLoad(){
        super.viewDidLoad()
        
        locationManger.delegate = self //分配并初始化一个位置管理器实例
        locationManger.desiredAccuracy =
         kCLLocationAccuracyBest //精確度設定
        
        loadingIndicator.startAnimating()  //開始滾動 loading狀態
        
        let background = UIImage(named:"background.png")
        self.view.backgroundColor = UIColor(patternImage:background!) //設置app背景，patternImage代表repeat自動拉伸的功能
        
        if ios8(){  //IOS8的話需要驗證
            locationManger.requestAlwaysAuthorization()
        }

        locationManger.startUpdatingLocation()//開始更新地理位置信息
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    func ios8() ->Bool{
        println(UIDevice.currentDevice().systemVersion.hasPrefix("8"))
        return UIDevice.currentDevice().systemVersion.hasPrefix("8")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        /*
             這個方法处理定位成功，manager参数表示位置管理器实例；locations为一个数组，是位置变化的集合，它按照时间变化的顺序存放。如果想获得设备的当前位置，
             只需要访问数组的最后一个元素即可。集合中每个对象类型是CLLocation，
        */
        var location:CLLocation = locations[locations.count-1] as CLLocation  //as的使用更接近自然語言。作用是類型轉換。。
        
        println(location.horizontalAccuracy)
        /*
            Core Location是iOS SDK中一个提供设备位置的框架。可以使用三种技术来获取位置：GPS、蜂窝或WiFi。在这些技术中，GPS最为精准，如果有GPS硬件，
            Core Location将优先使用它。如果设备没有GPS硬件(如WiFi iPad)或使用GPS获取当前位置时失败，Core Location将退而求其次，选择使用蜂窝或WiFi。
            Core Location的大多数功能是由位置管理器(CLLocationManager)提供的，可以使用位置管理器来指定位置更新的频率和精度，以及开始和停止接收这些更新。
        */
        if(location.horizontalAccuracy > 0){
            println(location.coordinate.latitude)
            println(location.coordinate.longitude)
            
            self.updateWeatherInfo(location.coordinate.latitude,
                longitude:location.coordinate.longitude)
            
            locationManger.stopUpdatingLocation()
        }
    }
    
    func updateWeatherInfo(latitude:CLLocationDegrees,longitude:CLLocationDegrees){
        /*
            AFNetworking是一个轻量级的iOS网络通信类库。它建立在NSURLConnection和NSOperation等类库的基础上，让很多网络通信功能的实现变得十分简单。
            它支持HTTP请求和基于REST的网络服务（包括GET、POST、 PUT、DELETE等）。
        */
        let manager = AFHTTPRequestOperationManager()
        let url = "http://api.openweathermap.org/data/2.5/weather"
        
        println(url)
        
        let params = ["lat":latitude,"lon":longitude,"cnt":0] //字典結構
        
        manager.GET(url, parameters: params, success: { (operation:AFHTTPRequestOperation!, responseObject:AnyObject!) in
                println("JSON:" + responseObject.description!)
                self.updateUISuccess(responseObject as NSDictionary) //將返回結果強制改為字典結構
                },
                failure:{(operation:AFHTTPRequestOperation!,error:NSError!) in
                println("Error:" + error.localizedDescription)}
        )
     }
    
    func updateUISuccess(jsonResult:NSDictionary!){
        self.loadingIndicator.hidden = true
        self.loadingIndicator.stopAnimating()
        self.loading.text = nil  //停止滾動并更新顯示
        
        //根據返回結果設置溫度和圖標
        if let tempResult = jsonResult["main"]?["temp"]? as? Double{
            var temperature:Double
            if(jsonResult["sys"]?["country"]? as String == "US")
            {
                temperature = round(((tempResult - 273.15)*1.8) + 32)
            }
            else
            {
                temperature = round (tempResult - 273.15)
            }
            
            self.temperature.text = "\(temperature)º"
            self.temperature.font = UIFont.boldSystemFontOfSize(60)
            
            var name = jsonResult["name"]? as String
            self.location.font = UIFont.boldSystemFontOfSize(25)
            self.location.text = "\(name)"
            
            var condition = (jsonResult["weather"]? as NSArray)[0]["id"]? as Int
            var sunrise = jsonResult["sys"]?["sunrise"]? as Double
            var sunset = jsonResult["sys"]?["sunset"]? as Double
            
            //根據日出跟日落時間去判斷使用圖標
            var nightTime = false
            var now = NSDate().timeIntervalSince1970
            
            if now < sunrise || now > sunset {
                nightTime = true
            }
            
            self.updateWeatherIcon(condition,nightTime:nightTime)
        }
        else{
            self.loading.text = "Weather Info is Invalid"
        }
        
    }
    
    func updateWeatherIcon(condition:Int ,nightTime:Bool){
        //根據condition去設置圖片
        if(condition < 300){
            if nightTime{
                self.icon.image = UIImage(named: "tstorm1_night")
            }
            else{
                self.icon.image = UIImage(named: "tstorm1")
            }
        }
        else if(condition < 500){
            self.icon.image = UIImage(named:"light_rain")
        }
        else if(condition < 600){
            self.icon.image = UIImage(named:"shower3")
        }
        else if(condition < 700){
            self.icon.image = UIImage(named:"snow4")
        }
        else if(condition < 771){
            if nightTime{
                self.icon.image = UIImage(named:"fog_night")
            }
            else{
                self.icon.image = UIImage(named: "fog")
            }
        }
        else if(condition < 800){
            self.icon.image = UIImage(named:"tstorm3")
        }
        else if(condition == 800){
            if nightTime{
                self.icon.image = UIImage(named: "sunny_night")
            }
            else{
                self.icon.image = UIImage(named: "sunny")
            }
        }
        else if(condition < 804){
            if nightTime{
                self.icon.image = UIImage(named: "cloudy2_night")
            }
            else{
                self.icon.image = UIImage(named: "cloudy2")
            }
        }
        else if(condition == 804){
            self.icon.image = UIImage(named:"overcast")
        }
        else if((condition >= 900 && condition < 903) || (condition > 904 && condition < 1000)){
            self.icon.image = UIImage(named: "tstorm3")
        }
        else if(condition == 903){
            self.icon.image = UIImage(named:"snow5")
        }
        else if(condition == 904){
            self.icon.image = UIImage(named:"sunny")
        }
        else{
            self.icon.image = UIImage(named:"dunno")
        }
    }
    
    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
         self.loading.text = "Address Info is Invalid"
    }
}

