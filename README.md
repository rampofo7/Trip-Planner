Trip Planner API

Overview

This Trip Planner API is a comprehensive solution implemented as part of the Comp Sci 214 course at Northwestern University, Fall 2023. It provides routing and searching services, allowing users to plan trips efficiently. The API supports various types of queries and utilizes data structures and algorithms selected for optimal performance.

Features
Position Management: Handles latitude and longitude information for mapping.
Road Segment Handling: Manages road segments with two endpoints for navigation.
Point of Interest (POI) Tracking: Stores POIs with categories and unique names, associating them with geographic locations.
Query Support: The API supports three main queries:
locate-all: Retrieves positions of all POIs within a given category.
plan-route: Determines the shortest path to a given POI from a starting position.
find-nearby: Lists POIs in proximity to a starting position within a specified category and limit.
Setup
Ensure you have Racket version 8.10 installed to run the provided code due to version-specific compiled files.

Clone the repository.
Navigate to the project directory.
Install dependencies as outlined in the provided project-lib.zip.
Run the main program file planner.rkt to interact with the API.
Usage
The API is designed to be used programmatically via Racket. Example usage is provided within the repository to demonstrate the capabilities and how to interact with the API.

Contributing
This project was part of an academic assignment, and while it is not actively maintained, contributions or suggestions are welcome. Please open an issue to discuss what you would like to change or submit a pull request.
