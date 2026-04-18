Feature: Monthly Multi-Site ACPM Traffic Monitoring
  As a Media Analyst
  I want a GitHub Action to scrape traffic data for multiple news outlets
  So that I have individual SVG visualizations and JSON data for each site's performance.

  Background:
    Given the GitHub Action is configured to trigger on a monthly CRON "0 0 1 * *"
    And the workflow supports a "workflow_dispatch" event for manual triggers
    And the Node.js environment has "jsdom" installed

  Scenario Outline: Scrape and generate assets for individual media sites
    Given the target source URL is "<url>"
    When the Node.js script fetches the HTML and parses rows with class "frequentation"
    And the script calculates the average visits and pages using the ACPM regex logic
    Then an SVG file named "<site_id>.svg" should be generated in the "docs" folder
    And the data should be stored in "stats.json" containing all sites' metrics

    Examples:
      | site_id  | url                                                                  |
      | lemonde  | https://www.acpm.fr/Support-Numerique/site/lemonde-fr                |
      | obs      | https://www.acpm.fr/Support-Numerique/site/nouvelobs-com             |
      | telerama | https://www.acpm.fr/Support-Numerique/site/telerama-fr               |
      | courrier | https://www.acpm.fr/Support-Numerique/site/courrierinternational-com |
      | diplo    | https://www.acpm.fr/Support-Numerique/site/monde-diplomatique-fr     |

  Scenario: Generate aggregated group SVG
    Given the script has finished processing all five sites
    When calculating totals across all sites
    Then a file named "lemonde-group.svg" should be generated in "docs" folder
    And it should display aggregated average visits and pages

  Scenario: Cache skip for recently updated sites
    Given a site was updated within the last 7 days
    When the scraper processes that site
    Then the script should skip fetching new data
    And should regenerate the SVG from cached data
    And should log "Skipping" message

  Scenario: Manual execution via GitHub Actions UI
    Given a user selects "Run workflow" from the GitHub Actions tab
    When the "workflow_dispatch" event is received
    Then the system should execute the full scrape and generate cycle for all sites
    And the process should bypass the monthly CRON wait time

  Scenario Outline: Graceful exit when a specific API/URL is unreachable
    Given the site "<site_id>" returns a connection error or 404
    When the scraping script attempts to process this site
    Then the script should log an error message for "<site_id>"
    And the script should skip this site and continue to the next
    And the overall process should continue normally

    Examples:
      | site_id |
      | lemonde |
      | obs     |

  Scenario: Rate limiting between requests
    Given the scraper is processing multiple sites
    When each site request completes
    Then the script should wait 1500ms before processing the next site
    And this delay should prevent API rate limiting
