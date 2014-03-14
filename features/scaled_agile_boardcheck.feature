Feature: Scaled agile
  As an agile enterprase
  I want to manage all aspects of planning from strategy via program to actual projects
  So that they get done according to the companys vision and strategy

  Background:
    Given the ecookbook project has the backlogs plugin enabled
      And scaled agile features are enabled and configured
      And no versions or issues exist
      And I am a scrum master of the project
      And I am member of some teams

  @javascript
  Scenario: Check the preconfigured boards
    Given some default generic boards are configured
      And I have defined the following sprints:
        | name       | sprint_start_date | effective_date |
        | Sprint 001 | 2010-01-01        | 2010-01-31     |
        | Sprint 002 | 2010-02-01        | 2010-02-28     |
        | Sprint 003 | 2010-04-01        | 2010-04-31     |
        | Sprint 004 | 2010-08-01        | 2010-08-31     |
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
    Given the current date is 2010-01-02
      And I am viewing the boards page
     Then I should see "Select board"
     Then show me a screenshot at /tmp/2.png
      And the boards should provide correct data for rows, columns and elements
