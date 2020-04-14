Feature: Add needs
  As a Call centre agent
  I want to add multiples needs to a person
  So that I can confirm details with people on the phone as their needs are identified

  Call centre manager: 200 new vulnerable people have been added to the list from online referrals,
  I need to *see what my staff are currently working on*
  so I know who has capacity and then have a way to divide and assign the new cases to my staff

  Service manager: 50 new referrals have come through to the emergency food service,
  I need to *know who is a priority (e.g. needs food today)*
  so I can prioritise assigning these cases to my team

  Call centre agent: I need to *know how I refer my calls or who I assign tasks to,
  e.g. Food service manager, ASC (not just people's names but their roles)*

  Call centre agent: As I'm confirming a residents details on the phone they
  begin telling me about whats going on in their life and I'm identifying some needs,
  I need to *easily be able to capture this without flicking back
  and forward between the tabs and having to save the page each time*

  Background:
    * I am logged into the system

  Scenario Outline: Add any needs
    Given a resident
    When I add needs "<need>"
    And I submit the add needs form
    Then the residents list of needs contains "<need>"
    Examples:
      | need                          |
      | Phone triage                  |
#      | Groceries and cooked meals    |
#      | Physical and mental wellbeing |
#      | Financial support             |
#      | Staying social                |
#      | Prescription pickups          |
#      | Book drops and entertainment  |
#      | Dog walking                   |
#
#  Scenario: Add multiple needs
#    Given a resident
#    When I add needs "Groceries and cooked meals"
#    And I add another need "Staying social"
#    And I add another need "Dog walking"
#    And I submit the add needs form
#    Then the residents list of needs contains "Groceries and cooked meals"
#    And the residents list of needs contains "Staying social"
#    And the residents list of needs contains "Dog walking"

#
#
#  Scenario: Person has no food today
#
#  Scenario: Person has a allergy
#
#  Scenario: Person has a cat
#
#  Scenario: Person lives on 4th floor of building and cannot use the stairs.
#
#  Scenario: Person has enough food for the next couple of days but has an underlying health condition
#  and is feeling very distressed.
#  They are unable to work at this time and are unsure how they will pay the rent this month.
#
#  Scenario: Person has food but is anxious about how their medicine will be collected / how they will get to a medical appointment
#
#  Scenario: Person does not have food and needs specialist food due to their medical condition (eg cancer treatment),
#  religion/culture eg halal/vegan
#
#  Scenario: Person is concerned about someone they know who is at risk – how they can get help
#
#  Scenario: Person has food but needs support taking waste out of their property