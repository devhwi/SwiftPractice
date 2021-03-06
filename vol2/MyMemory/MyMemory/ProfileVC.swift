//
//  ProfileVC.swift
//  MyMemory
//
//  Created by Jonghwi Lee on 2018. 7. 2..
//  Copyright © 2018년 Jonghwi Lee. All rights reserved.
//

import Foundation
import UIKit
import Alamofire
import LocalAuthentication

class ProfileVC: UIViewController, UITableViewDelegate, UITableViewDataSource,
        UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    var isCalling = false
    
    let profileImage = UIImageView() // 프로필 사진 이미지
    let tv = UITableView() // 프로필 목록
    
    let uinfo = UserInfoManager() // 개인 정보 관리 매니저
    
    override func viewWillAppear(_ animated: Bool) {
        // 토큰 인증 여부 체크
        self.tokenValidate()
    }
    
    override func viewDidLoad() {
        self.navigationItem.title = "프로필"
        
        // 뒤로 가기 버튼 처리
        let backBtn = UIBarButtonItem(title: "닫기", style: .plain, target: self, action: #selector(close(_:)))
        self.navigationItem.leftBarButtonItem = backBtn
        
        // 추가) 배경 이미지 설정 (프로필 이미지보다 아래쪽에 배치되어야 하므로 먼저 정의한다.)
        let bg = UIImage(named: "profile-bg")
        let bgImg = UIImageView(image: bg)
        
        bgImg.frame.size = CGSize(width: bgImg.frame.size.width, height: bgImg.frame.size.height)
        bgImg.center = CGPoint(x: self.view.frame.width / 2, y: 40)
        
        bgImg.layer.cornerRadius = bgImg.frame.size.width / 2
        bgImg.layer.borderWidth = 0
        bgImg.layer.masksToBounds = true
        self.view.addSubview(bgImg)
        
        // 1. 프로필 사진에 들어갈 기본 이미지
//        let image = UIImage(named: "account.jpg")
        let image = self.uinfo.profile
        
        // 2. 프로필 이미지 처리
        self.profileImage.image = image
        self.profileImage.frame.size = CGSize(width: 100, height: 100)
        self.profileImage.center = CGPoint(x: self.view.frame.width / 2, y: 270)
        
        // 3. 프로필 이미지 둥글게 만들기
        self.profileImage.layer.cornerRadius = self.profileImage.frame.width / 2
        self.profileImage.layer.borderWidth = 0
        self.profileImage.layer.masksToBounds = true
        
        // 4. 루트 뷰에 추가
        self.view.addSubview(self.profileImage)
        
        // 테이블
        self.tv.frame = CGRect(x: 0, y: self.profileImage.frame.origin.y + self.profileImage.frame.size.height + 20, width: self.view.frame.width, height: 100)
        self.tv.dataSource = self
        self.tv.delegate = self
        
        self.view.addSubview(self.tv)
        
        // 추가되는 부분
        self.view.bringSubview(toFront: self.tv)
        self.view.bringSubview(toFront: self.profileImage)
        
        // 내비게이션 바 숨김 처리
        self.navigationController?.navigationBar.isHidden = true
        
        self.drawBtn()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(profile(_:)))
        self.profileImage.addGestureRecognizer(tap)
        self.profileImage.isUserInteractionEnabled = true
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "cell")
        
        cell.textLabel?.font = UIFont.systemFont(ofSize: 14)
        cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 13)
        cell.accessoryType = .disclosureIndicator
        
        switch indexPath.row {
            case 0:
                cell.textLabel?.text = "이름"
//                cell.detailTextLabel?.text = "꼼꼼한 종휘 씨"
                cell.detailTextLabel?.text = self.uinfo.name ?? "Login Please"
            case 1:
                cell.textLabel?.text = "계정"
//                cell.detailTextLabel?.text = "hwiveloper@gmail.com"
                cell.detailTextLabel?.text = self.uinfo.account ?? "Login Please"
            default: ()
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.uinfo.isLogin == false {
            self.doLogin(self.tv)
        }
    }
    
    @objc func close(_ sender: Any) {
        self.presentingViewController?.dismiss(animated: true)
    }
    
    @objc func doLogin(_ sender: Any) {
        if self.isCalling == true {
            self.alert("응답을 기다리는 중입니다.\n잠시만 기다려 주세요.")
            return
        } else {
            self.isCalling = true
        }
        
        let loginAlert = UIAlertController(title: "LOGIN", message: nil, preferredStyle: .alert)
        
        // 알림창에 들어갈 로그인 폼 추가
        loginAlert.addTextField() { (tf) in
            tf.placeholder = "Your Account"
        }
        loginAlert.addTextField() { (tf) in
            tf.placeholder = "Password"
            tf.isSecureTextEntry = true
        }
        
        // 알림창 버튼 추가
        loginAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel) {(_) in
            self.isCalling = false
        })
        loginAlert.addAction(UIAlertAction(title: "Login", style: .destructive) { (_) in
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            
            let account = loginAlert.textFields?[0].text ?? ""
            let passwd = loginAlert.textFields?[1].text ?? ""
            
            self.uinfo.login(account: account, passwd: passwd, success: {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                self.isCalling = false
                
                self.tv.reloadData()
                self.profileImage.image = self.uinfo.profile
                self.drawBtn()
            }, fail: { msg in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                self.isCalling = false
                self.alert(msg)
            })
        })
        
        self.present(loginAlert, animated: true)
    }
    
    @objc func doLogout(_ sender: Any) {
        let msg = "로그아웃하시겠습니까?"
        let alert = UIAlertController(title: nil, message: msg, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "확인", style: .destructive) { (_) in
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
//            if self.uinfo.logout() {
//                self.tv.reloadData()
//                self.profileImage.image = self.uinfo.profile
//                self.drawBtn()
//            }
            self.uinfo.logout() {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                
                self.tv.reloadData()
                self.profileImage.image = self.uinfo.profile
                self.drawBtn()
            }
        })
        self.present(alert, animated: false)
    }
    
    func drawBtn() {
        // 버튼을 감쌀 뷰를 정의
        let v = UIView()
        v.frame.size.width = self.view.frame.width
        v.frame.size.height = 40
        v.frame.origin.x = 0
        v.frame.origin.y = self.tv.frame.origin.y + self.tv.frame.height
        v.backgroundColor = UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1.8)
        
        self.view.addSubview(v)
        
        // 버튼을 정의한다.
        let btn = UIButton(type: .system)
        btn.frame.size.width = 100
        btn.frame.size.height = 30
        btn.center.x = v.frame.size.width / 2
        btn.center.y = v.frame.size.height / 2
        
        // 로그인 상태에 따라 버튼 생성
        if self.uinfo.isLogin == true {
            btn.setTitle("로그아웃", for: .normal)
            btn.addTarget(self, action:#selector(doLogout(_:)), for: .touchUpInside)
        } else {
            btn.setTitle("로그인", for: .normal)
            btn.addTarget(self, action:#selector(doLogin(_:)), for: .touchUpInside)
        }
        
        v.addSubview(btn)
    }
    
    func imgPicker(_ source : UIImagePickerControllerSourceType) {
        let picker = UIImagePickerController()
        picker.sourceType = source
        picker.delegate = self
        picker.allowsEditing = true
        self.present(picker, animated: true)
    }
    
    @objc func profile(_ sender : UIButton) {
        // 로그인되어 있지 않을 경우에는 프로필 이미지 등록을 막고 대신 로그인 창을 띄워 준다.
        guard self.uinfo.account != nil else {
            self.doLogin(self)
            return
        }
        
        let alert = UIAlertController(title: nil, message: "사진을 가져올 곳을 선택해 주세요.", preferredStyle: .actionSheet)
        
        // 카메라를 사용할 수 있으면
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alert.addAction(UIAlertAction(title: "카메라", style: .default) {(_) in
                self.imgPicker(.camera)
            })
        }
        
        // 저장된 앨범을 사용할 수 있으면
        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) {
            alert.addAction(UIAlertAction(title: "저장된 앨범", style: .default) {(_) in
                self.imgPicker(.savedPhotosAlbum)
            })
        }
        
        // 포토 라이브러리를 사용할 수 있으면
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            alert.addAction(UIAlertAction(title: "포토 라이브러리", style: .default) {(_) in
                self.imgPicker(.photoLibrary)
            })
        }
        
        // 취소 버튼 추가
        alert.addAction(UIAlertAction(title: "취소", style: .cancel, handler: nil))
        
        // 액션 시트 창 실행
        self.present(alert, animated: true)
    }
    
    // 이미지를 선택하면 이 메소드가 자동으로 호출된다.
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
//        if let img = info[UIImagePickerControllerEditedImage] as? UIImage {
//            self.uinfo.profile = img
//            self.profileImage.image = img
//        }
//
//        // 이 구문을 누락하면 이미지 피커 컨트롤러 창은 닫히지 않는다.
//        picker.dismiss(animated: true)
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        if let img = info[UIImagePickerControllerEditedImage] as? UIImage {
            self.uinfo.newProfile(img, success: {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                self.profileImage.image = img
            }, fail: { msg in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                self.alert(msg)
            })
        }
        picker.dismiss(animated: true)
    }
    
    @IBAction func backProfileVC(_ segue: UIStoryboardSegue) {
        // 프로필 화면으로 돌아오는 segue를 생성
        // 메소드 내에서는 아무 동작 하지 않는다.
    }
}

extension ProfileVC {
    // 토큰 인증 메소드
    func tokenValidate() {
        // 응답 캐시를 사용하지 않도록
        URLCache.shared.removeAllCachedResponses()
        
        // 키 체인에 액세스 토큰이 없을 경우 유효성 검증을 하지 않는다.
        let tk = TokenUtils()
        guard let header = tk.getAuthorizationHeader() else {
            return
        }
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        // tokenValidate API 호출
        let url = "http://swiftapi.rubypaper.co.kr:2029/userAccount/tokenValidate"
        let validate = Alamofire.request(url, method: .post, encoding: JSONEncoding.default, headers: header)
        
        validate.responseJSON { res in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            
            print(res.result.value!) // 응답 결과 확인
            guard let jsonObject = res.result.value as? NSDictionary else {
                self.alert("잘못된 응답입니다.")
                return
            }
            // 응답 결과 처리
            let resultCode = jsonObject["result_code"] as! Int
            if resultCode != 0 {
                self.touchID()
            }
        }
    }
    
    // 터치 아이디 인증 메소드
    func touchID() {
        let context = LAContext()
        
        var error: NSError?
        let msg = "인증이 필요합니다."
        let deviceAuth = LAPolicy.deviceOwnerAuthenticationWithBiometrics // 인증 정책
        
        // 로컬 인증이 사용가능한지 여부 확인
        if context.canEvaluatePolicy(deviceAuth, error: &error) {
            context.evaluatePolicy(deviceAuth, localizedReason: msg) { (success, e) in
                if success { // 인증 성공
                    self.refresh() // 토큰 갱신
                } else { // 인증 실패
                    // 실패 대응 로직
                    print((e?.localizedDescription)!)
                    
                    switch (e!._code) {
                        case LAError.systemCancel.rawValue:
                            self.alert("시스템에 의해 인증이 취소되었습니다.")
                        case LAError.userCancel.rawValue:
                            self.alert("사용자에 의해 인증이 취소되었습니다.") {
                                self.commonLogout(true)
                            }
                        case LAError.userFallback.rawValue:
                            OperationQueue.main.addOperation {
                                self.commonLogout(true)
                            }
                        default:
                            OperationQueue.main.addOperation {
                                self.commonLogout(true)
                            }
                    }
                }
            }
        } else { // 인증창이 실행되지 못한 경우
            // 인증창 실행 불가 원인에 대한 대응 로직
            print(error!.localizedDescription)
            switch (error!.code) {
            case LAError.touchIDNotEnrolled.rawValue:
                print("터치 아이디가 등록되어 있지 않습니다.")
            case LAError.passcodeNotSet.rawValue:
                print("패스 코드가 설정되어 있지 않습니다.")
            default: // LAError.touchIDNotAvailable 포함
                print("터치 아이디를 사용할 수 없습니다.")
            }
            
            OperationQueue.main.addOperation {
                self.commonLogout(true)
            }
        }
    }
    
    // 토큰 갱신 메소드
    func refresh() {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        // 인증 헤더
        let tk = TokenUtils()
        let header = tk.getAuthorizationHeader()
        
        let refreshToken = tk.load("kr.co.rubypaper.MyMemory", account: "refreshToken")
        let param: Parameters = ["refreshToken" : refreshToken!]
        
        let url = "http://swiftapi.rubypaper.co.kr:2029/userAccount/refresh"
        let refresh = Alamofire.request(url, method: .post, parameters: param, encoding: JSONEncoding.default, headers: header)
        refresh.responseJSON { res in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            
            guard let jsonObject = res.result.value as? NSDictionary else {
                self.alert("잘못된 응답입니다.")
                return
            }
            
            let resultCode = jsonObject["result_code"] as! Int
            if resultCode == 0 {
                let accessToken = jsonObject["access_token"] as! String
                tk.save("kr.co.rubypaper.MyMemory", account: "accessToken", value: accessToken)
            } else {
                self.alert("인증이 만료되었으므로 다시 로그인해야 합니다.")
                OperationQueue.main.addOperation {
                    self.commonLogout()
                }
            }
        }
    }
    
    func commonLogout(_ isLogin: Bool = false) {
        let userInfo = UserInfoManager()
        userInfo.localLogout()
        
        self.tv.reloadData()
        self.profileImage.image = userInfo.profile
        self.drawBtn()
        
        if isLogin {
            self.doLogin(self)
        }
    }
}
