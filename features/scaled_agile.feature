Feature: Scaled agile
  As an agile enterprase
  I want to manage all aspects of planning from strategy via program to actual projects
  So that they get done according to the companys vision and strategy

  Background:
    Given the ecookbook project has the backlogs plugin enabled
      And scaled agile features are enabled and configured
      And no versions or issues exist
      And I am a scrum master of the project
      And I have defined the following sprints:
        | name       | sprint_start_date | effective_date |
        | Sprint 001 | 2010-01-01        | 2010-01-31     |
        | Sprint 002 | 2010-02-01        | 2010-02-28     |
        | Sprint 003 | 2010-03-01        | 2010-03-31     |
      And I have defined the following releases:
        | name    | project    | release_start_date | release_end_date |
        | Rel 1   | ecookbook  | 2010-01-01         | 2010-02-28       |
        | Rel 2   | ecookbook  | 2010-03-01         | 2010-06-01       |
      And I have deleted all existing issues
      And I have defined the following stories in the product backlog:
        | subject   | release | tracker |
        | Feature 1 | Rel 1   | Feature |
        | Story 1   |         | Story   |
        | Epic  2   |         | Epic    |
        | Feature 3 |         | Feature |
        | Story 4   |         | Story   |
      And I have defined the following stories in the following sprints:
        | subject | sprint     | release |
        | Story A | Sprint 001 | Rel 1   |
        | Story B | Sprint 001 |         |

  Scenario: view the global settings for scaled agile
    Given I am admin
      And I am on the homepage
     When I follow "Administration"
     When I follow "Plugins"
     When I follow "Configure"
     Then I should see "Enable scaled agile features"
      And the "settings[scaled_agile_enabled]" checkbox should be checked
      And the scaled agile tracker fields should be set to their correct trackers


  @javascript
  Scenario: Switch between boards
    Given some default generic boards are configured
      And I am viewing the boards page
     Then I should see "Select board"
      And I should see "1.2 Establish epics and features" within "#header"
     When I select "1.3 Put features in release" from "select_board"
     Then I should see "1.3 Put features in release" within "#header"

#  Scenario: Configure a board
#    Given I am have the rights to configure generic boards
#      And I am viewing the genericboard config page
#     When I click "Add board"
#     Then I should see the "new board" page
