import SwiftData
import XCTest
@testable import GaokaoCockpit

@MainActor
final class StudyTaskStoreTests: XCTestCase {
    func testCreateTasksFromPlanCreatesTasksAndSkipsExistingTitles() throws {
        let context = try makeContext()
        let dayPlan = try insertDayPlan(dayKey: "2026-05-22", mainSubject: LearningSubject.math.storageValue, in: context)

        _ = try StudyTaskStore.createTask(
            dayKey: dayPlan.dayKey,
            title: "函数导数压轴题",
            subject: LearningSubject.math.storageValue,
            category: .exercise,
            estimatedMinutes: 30,
            dayPlanId: dayPlan.id,
            in: context
        )

        let result = try StudyTaskStore.createTasksFromPlan(
            dayPlan: dayPlan,
            parsedTasks: [
                ParsedPlanTask(title: "函数导数压轴题", source: PlanTaskParser.Source.top),
                ParsedPlanTask(title: "英语阅读复盘", source: PlanTaskParser.Source.baseline),
                ParsedPlanTask(title: "物理模型加练", source: PlanTaskParser.Source.bonus)
            ],
            in: context
        )

        XCTAssertEqual(result.created, 2)
        XCTAssertEqual(result.skipped, 1)
        XCTAssertEqual(try StudyTaskStore.countTasks(for: dayPlan.dayKey, in: context), 3)

        let tasksByTitle = Dictionary(
            uniqueKeysWithValues: try StudyTaskStore.fetchTasks(for: dayPlan.dayKey, in: context).map { ($0.title, $0) }
        )
        let baselineTask = try XCTUnwrap(tasksByTitle["英语阅读复盘"])
        let bonusTask = try XCTUnwrap(tasksByTitle["物理模型加练"])

        XCTAssertEqual(baselineTask.dayPlanId, dayPlan.id)
        XCTAssertEqual(baselineTask.subject, LearningSubject.math.storageValue)
        XCTAssertEqual(baselineTask.category, StudyTaskCategory.review.storageValue)
        XCTAssertEqual(baselineTask.estimatedMinutes, 25)
        XCTAssertEqual(baselineTask.status, StudyTaskStatus.pending.storageValue)
        XCTAssertEqual(bonusTask.category, StudyTaskCategory.other.storageValue)
    }

    func testCreateTasksFromPlanUsesOtherSubjectWhenPlanSubjectIsBlank() throws {
        let context = try makeContext()
        let dayPlan = try insertDayPlan(dayKey: "2026-05-23", mainSubject: "   ", in: context)

        let result = try StudyTaskStore.createTasksFromPlan(
            dayPlan: dayPlan,
            parsedTasks: [
                ParsedPlanTask(title: "整理错题本", source: PlanTaskParser.Source.baseline)
            ],
            in: context
        )

        let task = try XCTUnwrap(try StudyTaskStore.fetchTasks(for: dayPlan.dayKey, in: context).first)
        XCTAssertEqual(result.created, 1)
        XCTAssertEqual(result.skipped, 0)
        XCTAssertEqual(task.subject, LearningSubject.other.storageValue)
    }

    func testCreateTaskPersistsCountsAndPostsChangeNotification() throws {
        let context = try makeContext()
        let dayKey = "2026-05-24"
        let notification = expectation(description: "StudyTaskStore posts didChange notification")
        let observer = NotificationCenter.default.addObserver(
            forName: StudyTaskStore.didChangeNotification,
            object: nil,
            queue: nil
        ) { note in
            guard note.userInfo?[StudyTaskStore.dayKeyUserInfoKey] as? String == dayKey else {
                return
            }

            notification.fulfill()
        }
        addTeardownBlock {
            NotificationCenter.default.removeObserver(observer)
        }

        _ = try StudyTaskStore.createTask(
            dayKey: dayKey,
            title: "英语阅读 C 篇",
            subject: LearningSubject.english.storageValue,
            category: .review,
            estimatedMinutes: 20,
            status: .done,
            in: context
        )

        wait(for: [notification], timeout: 0.5)
        XCTAssertEqual(try StudyTaskStore.countTasks(for: dayKey, in: context), 1)
        XCTAssertEqual(try StudyTaskStore.countCompletedTasks(for: dayKey, in: context), 1)
    }

    private func makeContext() throws -> ModelContext {
        let container = try AppModelContainerFactory.make(inMemory: true)
        return ModelContext(container)
    }

    private func insertDayPlan(
        dayKey: String,
        mainSubject: String,
        in context: ModelContext
    ) throws -> DayPlan {
        let dayPlan = DayPlan(
            dayKey: dayKey,
            date: try XCTUnwrap(DateKey.dateInterval(forKey: dayKey)?.start),
            mainSubject: mainSubject
        )
        context.insert(dayPlan)
        try context.save()
        return dayPlan
    }
}
