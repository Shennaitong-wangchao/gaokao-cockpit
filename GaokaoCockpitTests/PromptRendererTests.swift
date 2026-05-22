import XCTest
@testable import GaokaoCockpit

final class PromptRendererTests: XCTestCase {
    func testRenderReplacesTrimmedVariablesAndMissingValues() {
        let rendered = PromptRenderer.render(
            templateText: "今天做 {{ subject }}：{{ task }}。缺口：{{ missing }} / {{ blank }}",
            values: [
                " subject ": " 数学 ",
                "task": "导数",
                "blank": "   "
            ]
        )

        XCTAssertEqual(rendered, "今天做 数学：导数。缺口：未提供 / 未提供")
    }

    func testRenderReplacesRepeatedVariableNames() {
        let rendered = PromptRenderer.render(
            templateText: "{{name}} -> {{ name }}",
            values: ["name": "小明"]
        )

        XCTAssertEqual(rendered, "小明 -> 小明")
    }

    func testRenderLeavesPlainTextUnchanged() {
        let text = "没有变量的 Prompt"

        XCTAssertEqual(PromptRenderer.render(templateText: text, values: [:]), text)
    }
}
