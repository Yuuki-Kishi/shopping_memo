//
//  ContentView.swift
//  Watch shopping_memo Watch App
//
//  Created by 岸　優樹 on 2023/09/10.
//

import SwiftUI

struct ContentView: View {
    
    var viewModel = ShoppingMemoListViewModel()
    
    var testData = ["キャベツ", "トマト", "レタス", "ジャガイモ", "ダイコン", "ゴボウ", "モヤシ", "ピーマン"]
    
    @State var memoArray = [(memoId: String, memoCount: Int, shoppingMemo: String, isChecked: Bool, imageUrl: String)]()
    
    var body: some View {
        NavigationView {
            List {
                ForEach(0 ..< memoArray.count) { index in
                    let shoppingMemo = memoArray[index].shoppingMemo
                    var isChecked = memoArray[index].isChecked
                    let imageUrl = memoArray[index].imageUrl
                    HStack {
                        Button(action: {
                            isChecked = !isChecked
                            memoArray.remove(at: index)
                        }){
                            if isChecked {
                                Image(systemName: "checkmark.square")
                                    .foregroundColor(.white)
                            } else {
                                Image(systemName: "square")
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(width: 30, height: 25)
                        Text(shoppingMemo)
                        Spacer()
                        if imageUrl == "" {
                            Image(systemName: "plus.viewfinder")
                        } else {
                            Image(systemName: "photo")
                        }
                    }
                }
                
            }
            .navigationTitle("買い物")
            .environment(\.defaultMinListRowHeight, 25)

        }
        .onAppear {
            print("here")
            sendMessage(index: nil)
        }
    }
    
    private func sendMessage(index: Int?) {
        var messages: [String: Any]
        if let index {
            messages = ["request": "check", "index": index]
        } else {
            messages = ["request": "sendData"]
        }
        self.viewModel.session.sendMessage(messages, replyHandler: nil) { (error) in
            print(error.localizedDescription)
        }
    }
    
}

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView(, imageUrl: "aiuu")
//    }
//}
