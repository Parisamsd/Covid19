/* Covid19 Data Exxploration */
--We should only use rows in which continent is not empty

--Select data that we're going to be starting with
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM "coviddeaths"
WHERE continent IS NOT NULL
ORDER BY 1,2;


-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country
SELECT location, date, total_cases, total_deaths, ROUND((total_deaths/total_cases)*100,2) AS DeathPercentage
FROM "coviddeaths"
WHERE continent IS NOT NULL 
AND location = 'Iran'
ORDER BY 1,2;


-- Total Cases vs Population
-- Shows what percentage of population infected with Covid
SELECT location, date, population, total_cases, ROUND((total_cases/population)*100,2) AS PercentPopulationInfected
FROM "coviddeaths"
WHERE continent IS NOT NULL 
AND location = 'Iran'
ORDER BY 1,2;


-- Countries with Highest Infection Rate compared to Population
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population)*100) AS PercentPopulationInfected
FROM "coviddeaths"
WHERE continent IS NOT NULL 
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC


--Countries with highest death count per population
SELECT location, MAX(CAST(total_deaths as int)) AS HighestDeathCount
FROM "coviddeaths"
WHERE continent IS NOT NULL 
GROUP BY location
ORDER BY HighestDeathCount DESC

--Breaking down the data by the continent
SELECT continent, MAX(CAST(total_deaths as int)) AS HighestDeathCount
FROM "coviddeaths"
WHERE continent IS NOT NULL 
GROUP BY continent
ORDER BY HighestDeathCount DESC

-- GLOBAL NUMBERS

--percentage of people who died in the whole world
SELECT SUM(new_cases) AS total_cases,
	SUM(new_deaths) AS total_deaths,
	(SUM(new_deaths)/SUM(new_cases))*100 AS DeathPercentage
FROM "coviddeaths"
WHERE continent IS NOT NULL 

--Looking at total population vs. vaccination
SELECT dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS numeric)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated,
	
FROM coviddeaths dea
JOIN covidvaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

--Use CTE
WITH PopvsVac(continent,
			  location,
			  date,
			  population,
			  new_vaccination,
			  RollingPeopleVaccinated)
AS (
SELECT dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS numeric)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM coviddeaths dea
JOIN covidvaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3
)

--Temp Table
DROP TABLE IF EXISTS PercentPopulationVaccinated
CREATE TABLE PercentPopulationVaccinated(
continent varchar(255),
location varchar(255),
	date date,
	population numeric,
	new_vaccinations numeric,
	RollingPeopleVaccinated numeric
)
INSERT INTO PercentPopulationVaccinated
SELECT dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS numeric)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM coviddeaths dea
JOIN covidvaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

SELECT *, (RollingPeopleVaccinated/population)*100
FROM PopvsVac

--Create View to store data for later visualizations
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS numeric)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM coviddeaths dea
JOIN covidvaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL


/*

Queries used for Tableau Project

*/



-- 1. 

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From coviddeaths
--Where location like '%states%'
where continent is not null 
--Group By date
order by 1,2


-- 2. 

-- We take these out as they are not inluded in the above queries and want to stay consistent
-- European Union is part of Europe

Select location, SUM(cast(new_deaths as int)) as TotalDeathCount
From coviddeaths
--Where location like '%states%'
Where continent is null 
and location not in ('World', 'European Union', 'International')
Group by location
order by TotalDeathCount desc

-- 3.

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From coviddeaths
--Where location like '%states%'
Group by Location, Population
order by PercentPopulationInfected desc


-- 4.


Select Location, Population,date, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From coviddeaths
--Where location like '%states%'
Group by Location, Population, date
order by PercentPopulationInfected desc
