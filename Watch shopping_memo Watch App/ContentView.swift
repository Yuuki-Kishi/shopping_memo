//
//  ContentView.swift
//  Watch shopping_memo Watch App
//
//  Created by 岸　優樹 on 2023/09/10.
//

import SwiftUI

struct ContentView: View {
    
    var viewModel = WatchViewModel()
    
    @State var testData = ["キャベツ", "トマト", "レタス", "ジャガイモ", "ダイコン", "ゴボウ", "モヤシ", "ピーマン"]
    
    @State var listName: String!
    @State var memoArray = [(memoId: String, shoppingMemo: String, imageUrl: String)]()
    
    var body: some View {
        if !memoArray.isEmpty {
            NavigationView {
                List {
                    ForEach(0 ..< memoArray.count) { index in
                        //MARK: out of range
                        let shoppingMemo = memoArray[index].shoppingMemo
                        let imageUrl = memoArray[index].imageUrl
                        HStack {
                            Button(action: {
                                memoArray.remove(at: index)
                                sendMessage(index: index)
                            }){
                                Image(systemName: "square")
                                    .foregroundColor(.white)
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
                .navigationTitle(listName)
                .environment(\.defaultMinListRowHeight, 25)
            }
        } else {
            VStack {
                Image(systemName: "iphone.gen3.slash")
                    .resizable()
                    .foregroundColor(Color.red)
                    .frame(width: 50, height: 50)
                
                Text("データがありません。")
            }
            .onAppear {
                viewModel.watchDelegate = self
            }
        }
    }
    
    private func sendMessage(index: Int) {
        let messages: [String : Any] = ["request": "check", "index": index]
        self.viewModel.session.sendMessage(messages, replyHandler: nil) { (error) in
            print(error.localizedDescription)
        }
    }
}

extension ContentView: WatchViewModelDelegate {
    func reloadData() {
        listName = viewModel.listName
        memoArray = viewModel.memoArray
        print("memoArray:", memoArray)
    }
    
    
}
//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView(, imageUrl: "aiuu")
//    }
//}
