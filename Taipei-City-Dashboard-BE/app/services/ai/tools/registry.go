package tools

import (
	"TaipeiCityDashboardBE/app/models"
	"context"
	"encoding/json"
	"fmt"
	"regexp"
	"strconv"
	"strings"
	"time"
)

// ToolFunc defines the signature for a tool function
type ToolFunc func(ctx context.Context, args string) (string, error)

var registry = make(map[string]ToolFunc)

func init() {
	// Register demo tools
	Register("get_current_time", GetCurrentTime)
	Register("get_population_summary", GetPopulationSummary)
	Register("get_food_safety_table_data", GetFoodSafetyTableData)
}

// Register adds a tool to the registry
func Register(name string, fn ToolFunc) {
	registry[name] = fn
}

// Execute calls a registered tool with the given arguments
func Execute(ctx context.Context, name string, args string) (string, error) {
	fn, ok := registry[name]
	if !ok {
		return "", fmt.Errorf("tool %s not found", name)
	}
	return fn(ctx, args)
}

// PopulationArgs defines the arguments for the get_population_summary tool
type PopulationArgs struct {
	City string `json:"city"`
	Year int    `json:"year"`
}

// GetPopulationSummary queries the population age distribution from the dashboard database
func GetPopulationSummary(ctx context.Context, args string) (string, error) {
	var params PopulationArgs
	if err := parseArgs(args, &params); err != nil {
		return "", fmt.Errorf("invalid arguments: %v", err)
	}

	// Default to Taipei if not specified or unrecognized
	tableName := "population_age_distribution_tpe"
	cityName := "台北市"
	if params.City == "new_taipei" {
		tableName = "population_age_distribution_new_tpe"
		cityName = "新北市"
	}

	// Define result structure based on database schema
	var result struct {
		Year     int       `gorm:"column:year"`
		Young    int       `gorm:"column:young_population"`
		Working  int       `gorm:"column:working_age_population"`
		Elderly  int       `gorm:"column:elderly_population"`
		DataTime time.Time `gorm:"column:data_time"`
	}

	// Query the dashboard database
	err := models.DBDashboard.Table(tableName).
		Where("year = ?", params.Year).
		Order("data_time DESC"). // Get the latest record for that year
		First(&result).Error

	if err != nil {
		return "", fmt.Errorf("找不到 %s %d 年的人口統計資料: %v", cityName, params.Year, err)
	}

	// Format the response for the LLM
	return fmt.Sprintf(
		"【%d年 %s 人口結構概況】\n- 幼年人口 (0-14歲)：%d 人\n- 青壯年人口 (15-64歲)：%d 人\n- 老年人口 (65歲以上)：%d 人\n- 總人口： %d 人\n- 數據更新時間：%s",
		result.Year, cityName, result.Young, result.Working, result.Elderly,
		result.Young+result.Working+result.Elderly,
		result.DataTime.Format("2006-01-02"),
	), nil
}

// GetCurrentTime is a demo tool that returns the current Taipei time
func GetCurrentTime(ctx context.Context, args string) (string, error) {
	loc, err := time.LoadLocation("Asia/Taipei")
	if err != nil {
		// Fallback to UTC if timezone data is missing
		return time.Now().Format(time.RFC3339), nil
	}
	return time.Now().In(loc).Format("2006-01-02 15:04:05"), nil
}

type FoodSafetyTableArgs struct {
	Query          string `json:"query"`
	ComponentIndex string `json:"component_index"`
}

func GetFoodSafetyTableData(ctx context.Context, args string) (string, error) {
	var params FoodSafetyTableArgs
	if args != "" {
		if err := parseArgs(args, &params); err != nil {
			return "", fmt.Errorf("invalid arguments: %v", err)
		}
	}

	component := pickFoodSafetyComponent(params.ComponentIndex, params.Query)
	switch component {
	case "food_inspection_failures":
		return getInspectionFailuresSummary(ctx)
	case "food_grade_rank":
		return getFoodGradeSummary(ctx)
	case "foodborne_illness_trend":
		return getFoodPoisoningSummary(ctx, params.Query)
	case "district_food_risk":
		return getDistrictRiskSummary(ctx)
	case "inspection_enforcement_trend":
		return getInspectionEnforcementSummary(ctx, params.Query)
	case "market_quality_distribution":
		return getMarketQualitySummary(ctx)
	default:
		inspection, _ := getInspectionFailuresSummary(ctx)
		grade, _ := getFoodGradeSummary(ctx)
		poisoning, _ := getFoodPoisoningSummary(ctx, params.Query)
		risk, _ := getDistrictRiskSummary(ctx)
		enforcement, _ := getInspectionEnforcementSummary(ctx, params.Query)
		market, _ := getMarketQualitySummary(ctx)
		return fmt.Sprintf("%s\n\n%s\n\n%s\n\n%s\n\n%s\n\n%s", inspection, grade, poisoning, risk, enforcement, market), nil
	}
}

func pickFoodSafetyComponent(componentIndex, query string) string {
	allowed := map[string]bool{
		"food_inspection_failures":     true,
		"food_grade_rank":              true,
		"foodborne_illness_trend":      true,
		"district_food_risk":           true,
		"inspection_enforcement_trend": true,
		"market_quality_distribution":  true,
	}

	q := strings.ToLower(query)
	switch {
	case strings.Contains(q, "執法") || strings.Contains(q, "稽查") || strings.Contains(q, "取締") || strings.Contains(q, "工作量") || strings.Contains(q, "enforcement"):
		return "inspection_enforcement_trend"
	case strings.Contains(q, "優良市集") || strings.Contains(q, "市集") || strings.Contains(q, "市場") || strings.Contains(q, "星等") || strings.Contains(q, "market"):
		return "market_quality_distribution"
	case strings.Contains(q, "中毒") || strings.Contains(q, "病因") || strings.Contains(q, "患者") || strings.Contains(q, "foodborne"):
		return "foodborne_illness_trend"
	case strings.Contains(q, "分級") || strings.Contains(q, "評核") || strings.Contains(q, "安心") || strings.Contains(q, "餐廳") || strings.Contains(q, "food_grade"):
		return "food_grade_rank"
	case strings.Contains(q, "風險") || strings.Contains(q, "行政區") || strings.Contains(q, "業者密度") || strings.Contains(q, "違規率") || strings.Contains(q, "district"):
		return "district_food_risk"
	case strings.Contains(q, "抽驗") || strings.Contains(q, "不合格") || strings.Contains(q, "違規") || strings.Contains(q, "檢體") || strings.Contains(q, "inspection"):
		return "food_inspection_failures"
	default:
		if allowed[componentIndex] {
			return componentIndex
		}
		return ""
	}
}

func getInspectionFailuresSummary(ctx context.Context) (string, error) {
	var total int64
	if err := models.DBDashboard.WithContext(ctx).Table("food_inspection_failures").Count(&total).Error; err != nil {
		return "", err
	}
	var topCategories []struct {
		Name  string `json:"name" gorm:"column:name"`
		Count int64  `json:"count" gorm:"column:count"`
	}
	if err := models.DBDashboard.WithContext(ctx).Raw(`
		SELECT category AS name, COUNT(*) AS count
		FROM food_inspection_failures
		WHERE category IS NOT NULL
		GROUP BY category
		ORDER BY count DESC
		LIMIT 5
	`).Scan(&topCategories).Error; err != nil {
		return "", err
	}
	var latest []struct {
		Date     string `json:"date" gorm:"column:date"`
		District string `json:"district" gorm:"column:district"`
		Sample   string `json:"sample" gorm:"column:sample"`
		Reason   string `json:"reason" gorm:"column:reason"`
	}
	if err := models.DBDashboard.WithContext(ctx).Raw(`
		SELECT sample_date::text AS date, district, sample_name AS sample, reason
		FROM food_inspection_failures
		ORDER BY sample_date DESC NULLS LAST
		LIMIT 3
	`).Scan(&latest).Error; err != nil {
		return "", err
	}
	payload := map[string]interface{}{
		"table":          "食品抽驗不合格地圖",
		"total_records":  total,
		"top_categories": topCategories,
		"latest_records": latest,
	}
	return marshalToolPayload(payload)
}

func getFoodGradeSummary(ctx context.Context) (string, error) {
	var total int64
	if err := models.DBDashboard.WithContext(ctx).Table("food_hygiene_grade").Count(&total).Error; err != nil {
		return "", err
	}
	var topDistricts []struct {
		District string `json:"district" gorm:"column:district"`
		Count    int64  `json:"count" gorm:"column:count"`
	}
	if err := models.DBDashboard.WithContext(ctx).Raw(`
		SELECT district, COUNT(*) AS count
		FROM food_hygiene_grade
		WHERE district IS NOT NULL
		GROUP BY district
		ORDER BY count DESC
		LIMIT 5
	`).Scan(&topDistricts).Error; err != nil {
		return "", err
	}
	var samples []struct {
		District string `json:"district" gorm:"column:district"`
		Name     string `json:"name" gorm:"column:name"`
		Grade    string `json:"grade" gorm:"column:grade"`
	}
	if err := models.DBDashboard.WithContext(ctx).Raw(`
		SELECT district, business_name AS name, grade
		FROM food_hygiene_grade
		WHERE business_name IS NOT NULL
		ORDER BY district, business_name
		LIMIT 5
	`).Scan(&samples).Error; err != nil {
		return "", err
	}
	payload := map[string]interface{}{
		"table":             "餐飲衛生分級榜",
		"total_records":     total,
		"top_districts":     topDistricts,
		"sample_businesses": samples,
	}
	return marshalToolPayload(payload)
}

func getFoodPoisoningSummary(ctx context.Context, query string) (string, error) {
	targetYear := extractROCYear(query)
	var target struct {
		ROCYear  int `json:"roc_year" gorm:"column:roc_year"`
		Cases    int `json:"cases" gorm:"column:cases"`
		Patients int `json:"patients" gorm:"column:patients"`
	}
	targetQuery := `
		SELECT roc_year, cases, patients
		FROM food_poisoning_yearly_stats
	`
	targetArgs := []interface{}{}
	if targetYear > 0 {
		targetQuery += "WHERE roc_year = ? "
		targetArgs = append(targetArgs, targetYear)
	}
	targetQuery += "ORDER BY roc_year DESC LIMIT 1"
	if err := models.DBDashboard.WithContext(ctx).Raw(targetQuery, targetArgs...).Scan(&target).Error; err != nil {
		return "", err
	}
	if target.ROCYear == 0 {
		return "", fmt.Errorf("找不到民國 %d 年食品中毒統計資料", targetYear)
	}

	var previous struct {
		ROCYear  int `json:"roc_year" gorm:"column:roc_year"`
		Cases    int `json:"cases" gorm:"column:cases"`
		Patients int `json:"patients" gorm:"column:patients"`
	}
	_ = models.DBDashboard.WithContext(ctx).Raw(`
		SELECT roc_year, cases, patients
		FROM food_poisoning_yearly_stats
		WHERE roc_year < ?
		ORDER BY roc_year DESC
		LIMIT 1
	`, target.ROCYear).Scan(&previous).Error

	var topPathogens []struct {
		Pathogen string `json:"pathogen" gorm:"column:pathogen"`
		Patients int    `json:"patients" gorm:"column:patients"`
	}
	if err := models.DBDashboard.WithContext(ctx).Raw(`
		SELECT pathogen, patients
		FROM food_poisoning_pathogen_stats
		WHERE roc_year = ?
		ORDER BY patients DESC
		LIMIT 5
	`, target.ROCYear).Scan(&topPathogens).Error; err != nil {
		return "", err
	}
	var peakMonth struct {
		Month    int `json:"month" gorm:"column:month"`
		Cases    int `json:"cases" gorm:"column:cases"`
		Patients int `json:"patients" gorm:"column:patients"`
	}
	if err := models.DBDashboard.WithContext(ctx).Raw(`
		SELECT month, cases, patients
		FROM food_poisoning_monthly_stats
		WHERE roc_year = ?
		ORDER BY patients DESC
		LIMIT 1
	`, target.ROCYear).Scan(&peakMonth).Error; err != nil {
		return "", err
	}
	payload := map[string]interface{}{
		"table":         "食品中毒事件趨勢",
		"target_year":   target,
		"previous_year": previous,
		"top_pathogens": topPathogens,
		"peak_month":    peakMonth,
	}
	return marshalToolPayload(payload)
}

func extractROCYear(query string) int {
	_, rocYear := extractADAndROCYear(query)
	return rocYear
}

func extractADAndROCYear(query string) (int, int) {
	re := regexp.MustCompile(`(?:民國)?\s*(\d{2,4})\s*年`)
	matches := re.FindStringSubmatch(query)
	if len(matches) < 2 {
		return 0, 0
	}
	year, err := strconv.Atoi(matches[1])
	if err != nil {
		return 0, 0
	}
	if year >= 1912 {
		return year, year - 1911
	}
	return year + 1911, year
}

func getDistrictRiskSummary(ctx context.Context) (string, error) {
	var topRisk []struct {
		District string  `json:"district" gorm:"column:district"`
		Score    float64 `json:"score" gorm:"column:score"`
	}
	if err := models.DBDashboard.WithContext(ctx).Raw(`
		SELECT x_axis AS district, data AS score
		FROM district_food_risk
		ORDER BY data DESC
		LIMIT 5
	`).Scan(&topRisk).Error; err != nil {
		return "", err
	}
	payload := map[string]interface{}{
		"table":              "行政區食安風險指數",
		"top_risk_districts": topRisk,
	}
	return marshalToolPayload(payload)
}

func getInspectionEnforcementSummary(ctx context.Context, query string) (string, error) {
	targetADYear, targetROCYear := extractADAndROCYear(query)

	var taipei struct {
		Year  int `json:"year" gorm:"column:year"`
		Total int `json:"total" gorm:"column:total"`
	}
	taipeiSQL := `
		SELECT year, inspection_visits AS total
		FROM food_hygiene_work
		WHERE city = 'taipei' AND inspection_visits IS NOT NULL
	`
	taipeiArgs := []interface{}{}
	if targetADYear > 0 {
		taipeiSQL += "AND year = ? "
		taipeiArgs = append(taipeiArgs, targetADYear)
	}
	taipeiSQL += "ORDER BY year DESC LIMIT 1"
	if err := models.DBDashboard.WithContext(ctx).Raw(taipeiSQL, taipeiArgs...).Scan(&taipei).Error; err != nil {
		return "", err
	}

	var ntpc struct {
		Year  int `json:"year" gorm:"column:year"`
		Total int `json:"total" gorm:"column:total"`
	}
	ntpcSQL := `
		SELECT year, SUM(number)::integer AS total
		FROM vendor_enforcement_ntpc
		WHERE kind = '總計'
		  AND organ <> '政府警察局'
	`
	ntpcArgs := []interface{}{}
	if targetROCYear > 0 {
		ntpcSQL += "AND year = ? "
		ntpcArgs = append(ntpcArgs, targetROCYear)
	}
	ntpcSQL += `
		GROUP BY year
		ORDER BY year DESC
		LIMIT 1
	`
	if err := models.DBDashboard.WithContext(ctx).Raw(ntpcSQL, ntpcArgs...).Scan(&ntpc).Error; err != nil {
		return "", err
	}
	if targetADYear > 0 && taipei.Year == 0 && ntpc.Year == 0 {
		return "", fmt.Errorf("找不到 %d 年雙北食安執法工作量資料", targetADYear)
	}

	topDistrictYear := ntpc.Year
	if topDistrictYear == 0 {
		topDistrictYear = targetROCYear
	}

	var topNTPCDistricts []struct {
		District string `json:"district" gorm:"column:district"`
		Total    int    `json:"total" gorm:"column:total"`
	}
	topDistrictSQL := `
		SELECT district, SUM(number)::integer AS total
		FROM vendor_enforcement_ntpc
		WHERE kind = '總計'
		  AND organ <> '政府警察局'
		  AND district IS NOT NULL
	`
	topDistrictArgs := []interface{}{}
	if topDistrictYear > 0 {
		topDistrictSQL += "AND year = ? "
		topDistrictArgs = append(topDistrictArgs, topDistrictYear)
	} else {
		topDistrictSQL += "AND year = (SELECT MAX(year) FROM vendor_enforcement_ntpc) "
	}
	topDistrictSQL += `
		GROUP BY district
		ORDER BY total DESC
		LIMIT 5
	`
	if err := models.DBDashboard.WithContext(ctx).Raw(topDistrictSQL, topDistrictArgs...).Scan(&topNTPCDistricts).Error; err != nil {
		return "", err
	}

	payload := map[string]interface{}{
		"table":              "雙北食安執法工作量趨勢",
		"requested_year":     targetADYear,
		"taipei":             taipei,
		"new_taipei":         ntpc,
		"top_ntpc_districts": topNTPCDistricts,
	}
	return marshalToolPayload(payload)
}

func getMarketQualitySummary(ctx context.Context) (string, error) {
	var latestYear struct {
		Year int `json:"year" gorm:"column:year"`
	}
	if err := models.DBDashboard.WithContext(ctx).Raw(`
		SELECT MAX(year) AS year
		FROM market_quality_awards
	`).Scan(&latestYear).Error; err != nil {
		return "", err
	}

	var topDistricts []struct {
		District string `json:"district" gorm:"column:district"`
		Count    int    `json:"count" gorm:"column:count"`
	}
	if err := models.DBDashboard.WithContext(ctx).Raw(`
		SELECT district, COUNT(*)::integer AS count
		FROM market_quality_awards
		WHERE year = ? AND district IS NOT NULL
		GROUP BY district
		ORDER BY count DESC
		LIMIT 5
	`, latestYear.Year).Scan(&topDistricts).Error; err != nil {
		return "", err
	}

	var byCity []struct {
		City  string `json:"city" gorm:"column:city"`
		Count int    `json:"count" gorm:"column:count"`
	}
	if err := models.DBDashboard.WithContext(ctx).Raw(`
		SELECT city, COUNT(*)::integer AS count
		FROM market_quality_awards
		WHERE year = ?
		GROUP BY city
		ORDER BY city
	`, latestYear.Year).Scan(&byCity).Error; err != nil {
		return "", err
	}

	payload := map[string]interface{}{
		"table":         "雙北優良市集星等分布",
		"latest_year":   latestYear.Year,
		"by_city":       byCity,
		"top_districts": topDistricts,
	}
	return marshalToolPayload(payload)
}

func marshalToolPayload(payload interface{}) (string, error) {
	raw, err := json.Marshal(payload)
	if err != nil {
		return "", err
	}
	return string(raw), nil
}

// Helper to parse JSON arguments if needed in future tools
func parseArgs(args string, v interface{}) error {
	return json.Unmarshal([]byte(args), v)
}
