SELECT *
FROM [PortfolioProject]..CovidDeaths
ORDER BY 3,4

--SELECT *
--FROM [PortfolioProject]..CovidDeaths
--ORDER BY 3,4


--show the percentage total death vs total cases from covid in malaysia
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS Death_percentage
FROM [PortfolioProject]..CovidDeaths
WHERE location LIKE '%alaysia%' AND continent IS NOT NULL
ORDER BY 3 DESC

--show the percentage cases vs population from covid in malaysia by date
SELECT location, date, population,total_cases,  (total_cases/population)*100 AS cases_population_percentage
FROM [PortfolioProject]..CovidDeaths
ORDER BY 4 DESC

-- show the rank/percentage covid infection per population around the world

SELECT	location,population, MAX(total_cases) AS HighestInfectionCount, MAX(total_cases/population)*100 AS Percent_PopulationInfected
FROM	PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY 4 DESC

--show the percentage infection rate and malaysia global rank from covid
SELECT * 
FROM (SELECT *, ROW_NUMBER () OVER (ORDER BY Percent_PopulationInfected DESC) AS global_rank
FROM
		(SELECT	location,population, MAX(total_cases) AS HighestInfectionCount, MAX(total_cases/population)*100 AS Percent_PopulationInfected
		 FROM	PortfolioProject..CovidDeaths
		 WHERE continent IS NOT NULL
		 GROUP BY location, population) AS t
		 ) AS tt
WHERE location LIKE 'Malaysia'

-- show rank/percentage death per population around the world
SELECT location, population, MAX(CAST (total_deaths AS INT)) AS TotalDeathcount, MAX(CAST (total_deaths AS INT)/population)*100 AS Percent_DeathPopulation
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location,population
ORDER BY 4 DESC

-- show malaysia rank for percent of death per population
SELECT *
FROM (
SELECT *, ROW_NUMBER () OVER (ORDER BY Percent_DeathPopulation DESC) AS rank_global
FROM (
SELECT location, population, continent, MAX(CAST (total_deaths AS INT) )AS TotalDeathCount, MAX(CAST (total_deaths AS INT)/population)*100 AS Percent_DeathPopulation
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population, continent
) AS T) AS TT
WHERE   location LIKE 'Malaysia'
ORDER BY Percent_DeathPopulation DESC

--break down data by continent

--show continent with highest total death count
SELECT continent, MAX(CAST (total_deaths AS INT)) AS TotalDeathcount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY  TotalDeathcount DESC


--global number

SELECT SUM (new_cases) AS totalcases, SUM( CAST(new_deaths AS INT)) AS totaldeaths, SUM( CAST(new_deaths AS INT))/SUM (new_cases)*100 AS global_percentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1,2

/*SELECT SUM(totalcases)
FROM (SELECT date, SUM(new_cases) AS totalcases
FROM PortfolioProject..CovidDeaths
GROUP BY date) AS T*/


--joinn
SELECT *
FROM PortfolioProject..CovidDeaths AS covdea
JOIN
PortfolioProject..CovidVacc AS covvacc 
ON covdea.location=covvacc.location 
AND covdea.date=covvacc.date

--show rolling vaccinated by location
SELECT covdea.continent, covdea.location,covdea.date,covdea.population,covvacc.new_vaccinations
,SUM(CONVERT(INT,covvacc.new_vaccinations)) OVER(PARTITION BY covdea.location ORDER BY covdea.location, covdea.date) AS rollingpeoplevaccinated   
FROM PortfolioProject..CovidDeaths AS covdea
JOIN
PortfolioProject..CovidVacc AS covvacc 
ON covdea.location=covvacc.location 
AND covdea.date=covvacc.date
WHERE covdea.continent IS NOT NULL and covdea.location like '%Malaysia%'
ORDER BY 2,3

--percent rolling vaccinated per population

--use CTE
WITH table_vaccpercent (continent, location,date,population,new_vaccinations,rollingpeoplevaccinated)
AS (
SELECT covdea.continent, covdea.location,covdea.date,covdea.population,covvacc.new_vaccinations
,SUM(CONVERT(INT,covvacc.new_vaccinations)) OVER(PARTITION BY covdea.location ORDER BY covdea.location, covdea.date) AS rollingpeoplevaccinated   
FROM PortfolioProject..CovidDeaths AS covdea
JOIN
PortfolioProject..CovidVacc AS covvacc 
ON covdea.location=covvacc.location 
AND covdea.date=covvacc.date
WHERE covdea.continent IS NOT NULL)
--ORDER BY 2,3 desc)
SELECT *, (rollingpeoplevaccinated/population)*100 AS percent_vacc_populate
FROM table_vaccpercent
where location = 'Malaysia'
order by date desc

--use Temp Table

DROP TABLE IF EXISTS #vaccp
CREATE TABLE #vaccp
(
continent	nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rollingpeoplevaccinated numeric
)

INSERT INTO #vaccp 
SELECT covdea.continent, covdea.location,covdea.date,covdea.population,covvacc.new_vaccinations
,SUM(Cast(covvacc.new_vaccinations AS bigint)) OVER(PARTITION BY covdea.location ORDER BY covdea.location, covdea.date) AS rollingpeoplevaccinated   
FROM PortfolioProject..CovidDeaths AS covdea
JOIN
PortfolioProject..CovidVacc AS covvacc 
ON covdea.location=covvacc.location 
AND covdea.date=covvacc.date
--WHERE covdea.continent IS NOT NULL
--ORDER BY 2,3 desc)
SELECT *, (rollingpeoplevaccinated/population)*100 AS percent_vacc_populate
FROM #vaccp

--visualization table

CREATE VIEW PercentpopulationvaccinatedinMalaysia AS
SELECT covdea.continent, covdea.location,covdea.date,covdea.population,covvacc.new_vaccinations
,SUM(CONVERT(INT,covvacc.new_vaccinations)) OVER(PARTITION BY covdea.location ORDER BY covdea.location, covdea.date) AS rollingpeoplevaccinated   
FROM PortfolioProject..CovidDeaths AS covdea
JOIN
PortfolioProject..CovidVacc AS covvacc 
ON covdea.location=covvacc.location 
AND covdea.date=covvacc.date
WHERE covdea.continent IS NOT NULL and covdea.location like '%Malaysia%'

SELECT * 
FROM PercentpopulationvaccinatedinMalaysia