import XCTest
import Blackbird
@testable import RecordLib

// Generated, not yet passing

final class AssetsViewModelTests: XCTestCase {
    var viewModel: AssetsViewModel!
    var mockDB: Blackbird.Database!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create an in-memory database for testing
        mockDB = try Blackbird.Database.inMemoryDatabase()
        
        // Set up database schema
        try await mockDB.query("""
            CREATE TABLE IF NOT EXISTS things (
                id TEXT NOT NULL,
                account_id TEXT NOT NULL,
                upc TEXT,
                asin TEXT,
                elid TEXT,
                brand TEXT,
                model TEXT,
                color TEXT,
                tags TEXT,
                category TEXT,
                evidence_type TEXT,
                evidence_type_name TEXT,
                title TEXT,
                description TEXT,
                created_at REAL,
                updated_at REAL,
                PRIMARY KEY (account_id, id)
            )
        """)
        
        try await mockDB.query("""
            CREATE TABLE IF NOT EXISTS evidence (
                id TEXT NOT NULL,
                thing_account_id TEXT NOT NULL,
                thing_id TEXT NOT NULL,
                request_id TEXT,
                evidence_type INTEGER,
                data TEXT,
                local_file TEXT,
                created_at REAL,
                updated_at REAL,
                PRIMARY KEY (thing_account_id, id)
            )
        """)
        
        viewModel = AssetsViewModel(db: mockDB)
    }
    
    override func tearDown() async throws {
        viewModel = nil
        mockDB = nil
        try await super.tearDown()
    }
    
    // MARK: - Test Date Grouping
    
    func testLoadDatesWithNoData() async {
        // Given: No data in the database
        
        // When: Loading dates
        viewModel.loadDates()
        
        // Then: Should have no groups
        let expectation = XCTestExpectation(description: "Wait for groups to be loaded")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(self.viewModel.assetGroups.isEmpty)
            XCTAssertFalse(self.viewModel.isLoading)
            XCTAssertNil(self.viewModel.error)
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    func testLoadDatesWithSingleDate() async throws {
        // Given: A single thing with a known date
        let testDate = Date()
        let thing = Things(
            id: "test1",
            account_id: "acc1",
            created_at: testDate
        )
        try await mockDB.query("""
            INSERT INTO things (id, account_id, created_at)
            VALUES (?, ?, ?)
        """, thing.id, thing.account_id, thing.created_at)
        
        // When: Loading dates
        viewModel.loadDates()
        
        // Then: Should have one group for today
        let expectation = XCTestExpectation(description: "Wait for groups to be loaded")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.viewModel.assetGroups.count, 1)
            XCTAssertEqual(self.viewModel.assetGroups[0].title, "Today")
            XCTAssertFalse(self.viewModel.isLoading)
            XCTAssertNil(self.viewModel.error)
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    func testLoadDatesWithMultipleDates() async throws {
        // Given: Multiple things with different dates
        let calendar = Calendar.current
        let now = Date()
        
        // Create things for different time periods
        let todayThing = Things(
            id: "today",
            account_id: "acc1",
            created_at: now
        )
        
        let yesterdayThing = Things(
            id: "yesterday",
            account_id: "acc1",
            created_at: calendar.date(byAdding: .day, value: -1, to: now)!
        )
        
        let lastWeekThing = Things(
            id: "lastWeek",
            account_id: "acc1",
            created_at: calendar.date(byAdding: .day, value: -8, to: now)!
        )
        
        try await mockDB.query("""
            INSERT INTO things (id, account_id, created_at)
            VALUES (?, ?, ?)
        """, todayThing.id, todayThing.account_id, todayThing.created_at)
        
        try await mockDB.query("""
            INSERT INTO things (id, account_id, created_at)
            VALUES (?, ?, ?)
        """, yesterdayThing.id, yesterdayThing.account_id, yesterdayThing.created_at)
        
        try await mockDB.query("""
            INSERT INTO things (id, account_id, created_at)
            VALUES (?, ?, ?)
        """, lastWeekThing.id, lastWeekThing.account_id, lastWeekThing.created_at)
        
        // When: Loading dates
        viewModel.loadDates()
        
        // Then: Should have groups for today, yesterday, and this week
        let expectation = XCTestExpectation(description: "Wait for groups to be loaded")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.viewModel.assetGroups.count, 3)
            XCTAssertEqual(self.viewModel.assetGroups[0].title, "Today")
            XCTAssertEqual(self.viewModel.assetGroups[1].title, "Yesterday")
            XCTAssertEqual(self.viewModel.assetGroups[2].title, "This Week")
            XCTAssertFalse(self.viewModel.isLoading)
            XCTAssertNil(self.viewModel.error)
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    func testLoadDatesWithError() async {
        // Given: A nil database
        viewModel = AssetsViewModel(db: nil)
        
        // When: Loading dates
        viewModel.loadDates()
        
        // Then: Should have error state
        let expectation = XCTestExpectation(description: "Wait for error state")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(self.viewModel.assetGroups.isEmpty)
            XCTAssertFalse(self.viewModel.isLoading)
            XCTAssertNotNil(self.viewModel.error)
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    func testLoadDatesWithDatesInDifferentYears() async throws {
        // Given: Things from different years
        let calendar = Calendar.current
        let now = Date()
        
        let currentYearThing = Things(
            id: "currentYear",
            account_id: "acc1",
            created_at: now
        )
        
        let lastYearThing = Things(
            id: "lastYear",
            account_id: "acc1",
            created_at: calendar.date(byAdding: .year, value: -1, to: now)!
        )
        
        try await mockDB.query("""
            INSERT INTO things (id, account_id, created_at)
            VALUES (?, ?, ?)
        """, currentYearThing.id, currentYearThing.account_id, currentYearThing.created_at)
        
        try await mockDB.query("""
            INSERT INTO things (id, account_id, created_at)
            VALUES (?, ?, ?)
        """, lastYearThing.id, lastYearThing.account_id, lastYearThing.created_at)
        
        // When: Loading dates
        viewModel.loadDates()
        
        // Then: Should have groups for current year and previous year
        let expectation = XCTestExpectation(description: "Wait for groups to be loaded")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.viewModel.assetGroups.count, 2)
            XCTAssertEqual(self.viewModel.assetGroups[0].title, "Today")
            XCTAssertEqual(self.viewModel.assetGroups[1].title, "\(calendar.component(.year, from: now) - 1)")
            XCTAssertFalse(self.viewModel.isLoading)
            XCTAssertNil(self.viewModel.error)
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    func testLoadDatesWithDatesInSameMonth() async throws {
        // Given: Multiple things from the same month
        let calendar = Calendar.current
        let now = Date()
        
        let thing1 = Things(
            id: "thing1",
            account_id: "acc1",
            created_at: now
        )
        
        let thing2 = Things(
            id: "thing2",
            account_id: "acc1",
            created_at: calendar.date(byAdding: .day, value: -5, to: now)!
        )
        
        try await mockDB.query("""
            INSERT INTO things (id, account_id, created_at)
            VALUES (?, ?, ?)
        """, thing1.id, thing1.account_id, thing1.created_at)
        
        try await mockDB.query("""
            INSERT INTO things (id, account_id, created_at)
            VALUES (?, ?, ?)
        """, thing2.id, thing2.account_id, thing2.created_at)
        
        // When: Loading dates
        viewModel.loadDates()
        
        // Then: Should have appropriate groups
        let expectation = XCTestExpectation(description: "Wait for groups to be loaded")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.viewModel.assetGroups.count, 2)
            XCTAssertEqual(self.viewModel.assetGroups[0].title, "Today")
            XCTAssertEqual(self.viewModel.assetGroups[1].title, "This Week")
            XCTAssertFalse(self.viewModel.isLoading)
            XCTAssertNil(self.viewModel.error)
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 1.0)
    }
} 
