module SeedData
  # Departments, job titles and the base USD salary used to generate realistic data.
  # weight = how common the role is; base_usd = typical US annual base salary.
  module Catalog
    DEPARTMENTS = {
      "Engineering" => { weight: 32, titles: [["Software Engineer", 95_000, 5], ["Senior Software Engineer", 130_000, 3], ["QA Engineer", 80_000, 2], ["Staff Engineer", 170_000, 1], ["Engineering Manager", 165_000, 1]] },
      "Sales" => { weight: 16, titles: [["Sales Representative", 65_000, 5], ["Account Executive", 90_000, 3], ["Sales Manager", 125_000, 1.5], ["Sales Director", 170_000, 0.5]] },
      "Customer Support" => { weight: 14, titles: [["Support Agent", 42_000, 6], ["Senior Support Agent", 56_000, 3], ["Support Team Lead", 72_000, 1.5], ["Support Manager", 95_000, 0.5]] },
      "Operations" => { weight: 10, titles: [["Logistics Coordinator", 55_000, 4], ["Operations Analyst", 66_000, 4], ["Operations Manager", 105_000, 1.5], ["Director of Operations", 160_000, 0.5]] },
      "Product" => { weight: 8, titles: [["Product Designer", 100_000, 3], ["Product Manager", 120_000, 3], ["Senior Product Manager", 155_000, 2], ["Director of Product", 190_000, 0.5]] },
      "Marketing" => { weight: 8, titles: [["Marketing Specialist", 62_000, 4], ["Content Strategist", 70_000, 3], ["Marketing Manager", 105_000, 1.5], ["Head of Marketing", 160_000, 0.5]] },
      "Finance" => { weight: 7, titles: [["Accountant", 68_000, 4], ["Financial Analyst", 75_000, 4], ["Finance Manager", 120_000, 1.5], ["Controller", 150_000, 0.5]] },
      "Human Resources" => { weight: 5, titles: [["HR Coordinator", 52_000, 4], ["Recruiter", 66_000, 3], ["HR Business Partner", 90_000, 2], ["HR Manager", 105_000, 1]] }
    }.freeze

    # code => [headcount weight, pay level relative to the US, name pool]
    COUNTRIES = {
      "US" => [28, 1.0, :western], "IN" => [18, 0.28, :indian], "GB" => [10, 0.78, :western],
      "DE" => [10, 0.82, :german], "CA" => [7, 0.85, :western], "FR" => [6, 0.76, :french],
      "AU" => [6, 0.88, :western], "SG" => [5, 0.9, :chinese], "JP" => [5, 0.68, :japanese],
      "BR" => [5, 0.34, :brazilian]
    }.freeze

    NAMES = {
      western: [%w[James Emily Michael Sarah David Jessica Daniel Olivia Matthew Hannah Andrew Chloe Ryan Megan Thomas Grace],
                %w[Anderson Brooks Carter Donovan Edwards Fisher Grant Hughes Jenkins Kennedy Lawson Mitchell Nolan Parker Reynolds Sullivan]],
      german: [%w[Lukas Anna Felix Lena Jonas Marie Maximilian Sophie Leon Katharina Tobias Julia Stefan Greta],
               %w[Müller Schneider Fischer Weber Meyer Wagner Becker Hoffmann Schäfer Koch Richter Klein Wolf Neumann]],
      french: [%w[Louis Camille Hugo Chloé Lucas Léa Antoine Manon Julien Élodie Nicolas Inès Mathieu Clémence],
               %w[Martin Bernard Dubois Thomas Robert Petit Durand Leroy Moreau Simon Laurent Lefebvre Michel Garcia]],
      indian: [%w[Aarav Priya Rohan Ananya Vikram Neha Arjun Kavya Siddharth Meera Rahul Isha Karthik Divya],
               %w[Sharma Patel Iyer Reddy Gupta Nair Mehta Kapoor Singh Joshi Desai Menon Banerjee Chopra]],
      japanese: [%w[Haruto Yui Ren Sakura Takumi Aoi Kenji Mio Daiki Hana Yuto Rin Sota Akari],
                 %w[Sato Suzuki Takahashi Tanaka Watanabe Ito Yamamoto Nakamura Kobayashi Kato Yoshida Yamada Sasaki Matsumoto]],
      chinese: [["Wei", "Mei Ling", "Jun Hao", "Xin Yi", "Zhi Wei", "Jia Hui", "Kai Xiang", "Yan Ting", "Boon", "Hui Min", "Jian", "Pei Shan", "Ethan", "Priya"],
                %w[Tan Lim Lee Ng Goh Chua Ong Koh Teo Chan Wong Ho Yeo Sim]],
      brazilian: [%w[Gabriel Beatriz Rafael Larissa Thiago Fernanda Bruno Camila Gustavo Juliana Mateus Isabela Felipe Letícia],
                  %w[Silva Santos Oliveira Souza Costa Pereira Rodrigues Almeida Nascimento Lima Araújo Ribeiro Carvalho Ferreira]]
    }.freeze
  end
end
