/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import EditorHistoryPlugin
import Lexical
import LexicalInlineImagePlugin
import LexicalLinkPlugin
import LexicalListPlugin
import UIKit

class ViewController: UIViewController, UIToolbarDelegate {

  var lexicalView: LexicalView?
  weak var toolbar: UIToolbar?
  weak var hierarchyView: UIView?
  private let editorStatePersistenceKey = "editorState"

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground

    let editorHistoryPlugin = EditorHistoryPlugin()
    let toolbarPlugin = ToolbarPlugin(viewControllerForPresentation: self, historyPlugin: editorHistoryPlugin)
    let toolbar = toolbarPlugin.toolbar
    toolbar.delegate = self

    let hierarchyPlugin = NodeHierarchyViewPlugin()
    let hierarchyView = hierarchyPlugin.hierarchyView

    let listPlugin = ListPlugin()
    let imagePlugin = InlineImagePlugin()

    let linkPlugin = LinkPlugin()

    let theme = Theme()
    theme.indentSize = 40.0
    theme.link = [
      .foregroundColor: UIColor.systemBlue
    ]

    let editorConfig = EditorConfig(theme: theme, plugins: [toolbarPlugin, listPlugin, hierarchyPlugin, imagePlugin, linkPlugin, editorHistoryPlugin])
    let lexicalView = LexicalView(editorConfig: editorConfig, featureFlags: FeatureFlags())

    linkPlugin.lexicalView = lexicalView

    self.lexicalView = lexicalView
    self.toolbar = toolbar
    self.hierarchyView = hierarchyView

    self.restoreEditorState()

    view.addSubview(lexicalView)
    view.addSubview(toolbar)
    view.addSubview(hierarchyView)

    navigationItem.title = "Lexical"
    setUpExportMenu()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()

    if let lexicalView, let toolbar, let hierarchyView {
      let safeAreaInsets = self.view.safeAreaInsets
      let hierarchyViewHeight = 300.0

      toolbar.frame = CGRect(
        x: 0,
        y: safeAreaInsets.top,
        width: view.bounds.width,
        height: 44)
      lexicalView.frame = CGRect(
        x: 0,
        y: toolbar.frame.maxY,
        width: view.bounds.width,
        height: view.bounds.height - toolbar.frame.maxY - safeAreaInsets.bottom - hierarchyViewHeight)
      hierarchyView.frame = CGRect(
        x: 0,
        y: lexicalView.frame.maxY,
        width: view.bounds.width,
        height: hierarchyViewHeight)
    }
  }

  func persistEditorState() {
    guard let editor = lexicalView?.editor else {
      return
    }

    let currentEditorState = editor.getEditorState()

    // turn the editor state into stringified JSON
    guard let jsonString = try? currentEditorState.toJSON() else {
      return
    }

    UserDefaults.standard.set(jsonString, forKey: editorStatePersistenceKey)
  }

  func restoreEditorState() {
    guard let editor = lexicalView?.editor else {
      return
    }

//    guard let jsonString = UserDefaults.standard.value(forKey: editorStatePersistenceKey) as? String else {
//      return
//    }
      let jsonString = TestModel.smallJson

    // turn the JSON back into a new editor state
    guard let newEditorState = try? EditorState.fromJSON(json: jsonString, editor: editor) else {
      return
    }

    // install the new editor state into editor
    try? editor.setEditorState(newEditorState)
  }

  func setUpExportMenu() {
    let menuItems = OutputFormat.allCases.map { outputFormat in
      UIAction(
        title: "Export \(outputFormat.title)",
        handler: { [weak self] action in
          self?.showExportScreen(outputFormat)
        })
    }
    let menu = UIMenu(title: "Export as…", children: menuItems)
    let barButtonItem = UIBarButtonItem(title: "Export", style: .plain, target: nil, action: nil)
    barButtonItem.menu = menu
    navigationItem.rightBarButtonItem = barButtonItem
  }

  func showExportScreen(_ type: OutputFormat) {
    guard let editor = lexicalView?.editor else { return }
    let vc = ExportOutputViewController(editor: editor, format: type)
    navigationController?.pushViewController(vc, animated: true)
  }

  func position(for bar: UIBarPositioning) -> UIBarPosition {
    return .top
  }
}

enum TestModel {
    static let json: String = """
        {"root":{"children":[{"children":[{"children":[{"detail":0,"format":0,"mode":"normal","style":"","text":"first number line","type":"text","version":1}],"direction":"ltr","format":"","indent":0,"type":"listitem","version":1,"value":1},{"children":[{"detail":0,"format":0,"mode":"normal","style":"","text":"second number line","type":"text","version":1},{"type":"linebreak","version":1}],"direction":"ltr","format":"","indent":0,"type":"listitem","version":1,"value":2}],"direction":"ltr","format":"","indent":0,"type":"list","version":1,"listType":"number","start":1,"tag":"ol"},{"children":[{"children":[{"detail":0,"format":0,"mode":"normal","style":"","text":"Dotes","type":"text","version":1}],"direction":"ltr","format":"","indent":0,"type":"listitem","version":1,"value":1},{"children":[{"detail":0,"format":0,"mode":"normal","style":"","text":"more dotes","type":"text","version":1}],"direction":"ltr","format":"","indent":0,"type":"listitem","version":1,"value":2}],"direction":"ltr","format":"","indent":0,"type":"list","version":1,"listType":"bullet","start":1,"tag":"ul"},{"children":[{"detail":0,"format":0,"mode":"normal","style":"","text":" ","type":"text","version":1},{"type":"linebreak","version":1},{"detail":0,"format":0,"mode":"normal","style":"","text":"First note text.","type":"text","version":1},{"type":"linebreak","version":1},{"detail":0,"format":1,"mode":"normal","style":"","text":"First Note Bold Text.","type":"text","version":1},{"type":"linebreak","version":1},{"detail":0,"format":2,"mode":"normal","style":"","text":"First Note Italic text","type":"text","version":1},{"type":"linebreak","version":1},{"detail":0,"format":8,"mode":"normal","style":"","text":"First note undelined text","type":"text","version":1},{"type":"linebreak","version":1},{"detail":0,"format":4,"mode":"normal","style":"","text":"First note crosed text","type":"text","version":1}],"direction":"ltr","format":"center","indent":0,"type":"paragraph","version":1,"textFormat":0,"textStyle":""},{"children":[{"detail":0,"format":0,"mode":"normal","style":"","text":"text aligned to left","type":"text","version":1},{"type":"linebreak","version":1},{"detail":0,"format":0,"mode":"normal","style":"","text":"aligned to left","type":"text","version":1}],"direction":"ltr","format":"left","indent":0,"type":"paragraph","version":1,"textFormat":0,"textStyle":""},{"children":[{"type":"linebreak","version":1},{"detail":0,"format":0,"mode":"normal","style":"","text":"text aligned to right","type":"text","version":1},{"type":"linebreak","version":1},{"detail":0,"format":0,"mode":"normal","style":"","text":"aligned to right","type":"text","version":1}],"direction":"ltr","format":"right","indent":0,"type":"paragraph","version":1,"textFormat":0,"textStyle":""},{"children":[],"direction":null,"format":"right","indent":0,"type":"paragraph","version":1,"textFormat":0,"textStyle":""},{"children":[{"detail":0,"format":0,"mode":"normal","style":"","text":"some aligned to center ","type":"text","version":1}],"direction":"ltr","format":"center","indent":0,"type":"paragraph","version":1,"textFormat":0,"textStyle":""},{"children":[],"direction":null,"format":"center","indent":0,"type":"paragraph","version":1,"textFormat":0,"textStyle":""},{"children":[{"detail":0,"format":0,"mode":"normal","style":"","text":"some aligned four","type":"text","version":1},{"type":"linebreak","version":1},{"type":"linebreak","version":1},{"type":"linebreak","version":1},{"detail":0,"format":2,"mode":"normal","style":"","text":"Title 1","type":"text","version":1},{"type":"linebreak","version":1}],"direction":"ltr","format":"left","indent":0,"type":"heading","version":1,"tag":"h1"},{"children":[{"type":"linebreak","version":1},{"detail":0,"format":0,"mode":"normal","style":"","text":"Title 2","type":"text","version":1},{"type":"linebreak","version":1}],"direction":"ltr","format":"","indent":0,"type":"heading","version":1,"tag":"h2"},{"children":[],"direction":null,"format":"","indent":0,"type":"heading","version":1,"tag":"h2"},{"children":[{"detail":0,"format":0,"mode":"normal","style":"","text":"Title 2","type":"text","version":1},{"type":"linebreak","version":1},{"type":"linebreak","version":1}],"direction":"ltr","format":"","indent":0,"type":"heading","version":1,"tag":"h3"},{"children":[{"detail":0,"format":0,"mode":"normal","style":"","text":"some text when dots was pressed londer","type":"text","version":1}],"direction":"ltr","format":"","indent":0,"type":"quote","version":1},{"children":[],"direction":null,"format":"","indent":0,"type":"quote","version":1},{"children":[{"detail":0,"format":0,"mode":"normal","style":"","text":"some text","type":"text","version":1},{"type":"linebreak","version":1},{"type":"linebreak","version":1},{"detail":0,"format":0,"mode":"normal","style":"","text":"hello text","type":"text","version":1}],"direction":"ltr","format":"","indent":0,"type":"quote","version":1},{"children":[],"direction":null,"format":"","indent":0,"type":"quote","version":1},{"children":[],"direction":null,"format":"","indent":0,"type":"quote","version":1},{"children":[{"detail":0,"format":0,"mode":"normal","style":"","text":"long text","type":"text","version":1}],"direction":"ltr","format":"","indent":0,"type":"quote","version":1},{"children":[],"direction":"ltr","format":"","indent":0,"type":"paragraph","version":1,"textFormat":0,"textStyle":""},{"children":[{"children":[{"detail":0,"format":0,"mode":"normal","style":"","text":"some regular text","type":"text","version":1}],"direction":"ltr","format":"","indent":0,"type":"listitem","version":1,"value":1},{"children":[{"detail":0,"format":1,"mode":"normal","style":"","text":"some bold text","type":"text","version":1}],"direction":"ltr","format":"","indent":0,"type":"listitem","version":1,"value":2},{"children":[{"detail":0,"format":2,"mode":"normal","style":"","text":"some italic text","type":"text","version":1}],"direction":"ltr","format":"","indent":0,"type":"listitem","version":1,"value":3},{"children":[{"detail":0,"format":3,"mode":"normal","style":"","text":"some bold + italic text","type":"text","version":1}],"direction":"ltr","format":"","indent":0,"type":"listitem","version":1,"value":4},{"children":[{"detail":0,"format":4,"mode":"normal","style":"","text":"some strikethrough text","type":"text","version":1}],"direction":"ltr","format":"","indent":0,"type":"listitem","version":1,"value":5},{"children":[{"detail":0,"format":5,"mode":"normal","style":"","text":"some Bold + Strikethrough text","type":"text","version":1}],"direction":"ltr","format":"","indent":0,"type":"listitem","version":1,"value":6},{"children":[{"detail":0,"format":6,"mode":"normal","style":"","text":"some italic + Strikethrough text","type":"text","version":1}],"direction":"ltr","format":"","indent":0,"type":"listitem","version":1,"value":7},{"children":[{"detail":0,"format":7,"mode":"normal","style":"","text":"some  Bold + Italic + Strikethrough text","type":"text","version":1}],"direction":"ltr","format":"","indent":0,"type":"listitem","version":1,"value":8},{"children":[{"detail":0,"format":8,"mode":"normal","style":"","text":"some underline text","type":"text","version":1}],"direction":"ltr","format":"","indent":0,"type":"listitem","version":1,"value":9},{"children":[{"detail":0,"format":9,"mode":"normal","style":"","text":"some Bold + Underline text","type":"text","version":1}],"direction":"ltr","format":"","indent":0,"type":"listitem","version":1,"value":10},{"children":[{"detail":0,"format":10,"mode":"normal","style":"","text":"some  Italic + Underline text","type":"text","version":1}],"direction":"ltr","format":"","indent":0,"type":"listitem","version":1,"value":11},{"children":[{"detail":0,"format":11,"mode":"normal","style":"","text":"some Bold + Italic + Underline text","type":"text","version":1}],"direction":"ltr","format":"","indent":0,"type":"listitem","version":1,"value":12},{"children":[{"detail":0,"format":12,"mode":"normal","style":"","text":"some Underline + Strikethrough text","type":"text","version":1}],"direction":"ltr","format":"","indent":0,"type":"listitem","version":1,"value":13},{"children":[{"detail":0,"format":13,"mode":"normal","style":"","text":"some Bold + Underline + Strikethrough text","type":"text","version":1}],"direction":"ltr","format":"","indent":0,"type":"listitem","version":1,"value":14},{"children":[{"detail":0,"format":14,"mode":"normal","style":"","text":"some Italic + Underline + Strikethrought text","type":"text","version":1}],"direction":"ltr","format":"","indent":0,"type":"listitem","version":1,"value":15},{"children":[{"detail":0,"format":15,"mode":"normal","style":"","text":"some Bold + Italic + Undeline + Strikethrought text","type":"text","version":1}],"direction":"ltr","format":"","indent":0,"type":"listitem","version":1,"value":16}],"direction":"ltr","format":"","indent":0,"type":"list","version":1,"listType":"number","start":1,"tag":"ol"},{"children":[],"direction":"ltr","format":"","indent":0,"type":"paragraph","version":1,"textFormat":13,"textStyle":""},{"children":[],"direction":null,"format":"","indent":0,"type":"paragraph","version":1,"textFormat":15,"textStyle":""},{"children":[],"direction":"ltr","format":"","indent":0,"type":"paragraph","version":1,"textFormat":15,"textStyle":""}],"direction":"ltr","format":"","indent":0,"type":"root","version":1}}
        """
    static let smallJson: String = """
             {"root":{"type":"root","format":null,"indent":0,"version":1,"direction":null,"children":[{"format":"right","children":[{"format":1,"type":"text","mode":"normal","text":"title ","version":1,"style":"","detail":0},{"format":2,"type":"text","text":"fdsfsdfsd","detail":0,"mode":"normal","version":1,"style":""}],"direction":"ltr","version":1,"indent":0,"type":"quote"},{"format":"center","children":[{"text":"Авоыдлаоылвдодлвы","mode":"normal","detail":0,"style":"","version":1,"format":2,"type":"text"}],"direction":null,"version":1,"indent":0,"type":"paragraph"}]}}
       """
}
