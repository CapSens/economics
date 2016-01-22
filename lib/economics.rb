require 'flt'

module Economics
  class Loan
    include ActiveModel::Model
    include Flt

    attr_accessor :e_fee
    attr_accessor :e_amount
    attr_accessor :e_start_date
    attr_accessor :e_rate
    attr_accessor :e_duration
    attr_accessor :p_amount
    attr_accessor :p_ps
    attr_accessor :p_ir
    attr_accessor :fee
    attr_accessor :rate
    attr_accessor :ps
    attr_accessor :ir
    attr_accessor :_cache

    validates :e_amount,     presence: true
    validates :e_start_date, presence: true
    validates :e_duration,   presence: true
    validates :p_amount,     presence: true
    validates :ps,           presence: true
    validates :ir,           presence: true
    validates :rate,         presence: true
    validates :fee,          presence: true

    def cached method, index, &block
      _name = [method, index].join('-')
      _cache[_name].presence || _cache[_name] = block.call
    end

    def amortized_for index
      cached __method__, index do
        score_1 = capital_for(index) / e_amount
        score_2 = score_1 * 100.0
      end
    end

    def capital_for index
      cached __method__, index do
        score_1 = 1 + e_rate
        score_2 = (score_1 ** (e_duration)) - 1
        score_3 = (score_1 ** index) - 1
        score_4 = (score_1 ** (index-1)) - 1
        score_5 = index == 0 ? 0 : (e_amount * (score_4 / score_2))
        score_6 = e_amount * (score_3 / score_2)
        score_7 = score_6 - score_5
      end
    end

    def capital_left_for index
      cached __method__, index do
        return e_amount if index == 0
        score_1 = capital_left_for(index - 1)
        score_2 = capital_for(index)
        score_3 = score_1 - score_2
      end
    end

    def interest_for index
      cached __method__, index do
        return 0 if index == 0
        score = capital_left_for(index - 1) * e_rate
      end
    end

    def fee_for index
      cached __method__, index do
        return 0 if index == 0
        score_1 = (index - 1) / 12
        score_2 = capital_left_for(12 * score_1)
        score_3 = e_fee * score_2
        score_4 = score_3 / 12.0
      end
    end

    def monthly_amount_for index
      cached __method__, index do
        return 0 if index == 0
        score_1 = (1 + e_rate) ** e_duration
        score_2 = fee_for(index)
        score_3 = e_amount * e_rate * score_1
        score_4 = score_1 - 1
        score_5 = score_3 / score_4
        score_6 = score_2 + score_5
      end
    end

    def p_capital_rbt_for index
      cached __method__, index do
        score = amortized_for(index) * p_amount / 100.0
      end
    end

    def p_check_for index
      cached __method__, index do
        score_1 = p_amount / e_amount
        score_2 = capital_for(index)
        score_3 = score_1 * score_2
      end
    end

    def p_interest_brut_for index
      cached __method__, index do
        score_1 = p_amount / e_amount
        score_2 = interest_for(index)
        score_3 = score_1 * score_2
      end
    end

    def p_interest_net_for index
      cached __method__, index do
        score_1 = p_interest_brut_for(index)
        score_2 = p_fee_credit_for(0)
        score_3 = p_ps_ir_for(index)
        score_4 = score_1 - score_2 - score_3
      end
    end

    def p_fee_credit_for index
      cached __method__, index do
        0.0
      end
    end

    def p_ps_ir_for index
      cached __method__, index do
        score_1 = p_ps + p_ir
        score_2 = p_interest_brut_for(index)
        score_3 = score_1 * score_2
      end
    end

    def p_pf_for index
      cached __method__, index do
        return p_amount if index == 0

        score_1 = index == 1 ? 0.0 : p_pf_for(index - 1)
        score_2 = p_interest_net_for(index)
        score_3 = p_capital_rbt_for(index)
        score_4 = score_1 + score_2 + score_3
      end
    end

    def p_m_net_for index
      cached __method__, index do
        score_1 = p_capital_rbt_for(index)
        score_2 = p_interest_net_for(index)
        score_3 = score_1 + score_2
      end
    end

    def p_m_brut_for index
      cached __method__, index do
        score_1 = p_check_for(index)
        score_2 = p_interest_brut_for(index)
        score_3 = score_1 + score_2
      end
    end

    def table
      setup && (0..e_duration).map do |index|
        record = OpenStruct.new
        record.execution_date = (Date.parse(e_start_date) + index.months).to_date
        record.capital_left = capital_left_for(index)
        record.fee = fee_for(index)
        record.monthly_amount = monthly_amount_for(index)
        record.capital = capital_for(index)
        record.interest = interest_for(index)
        record.p_amortized = amortized_for(index)
        record.p_capital_rbt = p_capital_rbt_for(index)
        record.p_check = p_check_for(index)
        record.p_interest_brut = p_interest_brut_for(index)
        record.p_ps_ir = p_ps_ir_for(index)
        record.p_interest_net = p_interest_net_for(index)
        record.p_pf = p_pf_for(index)
        record.p_m_net = p_m_net_for(index)
        record.p_m_brut = p_m_brut_for(index)
        record
      end
    end

    private

    def setup
      self.e_fee      = fee.to_d / 100.00
      self.e_rate     = rate.to_d / 100.00 / 12.0
      self.e_amount   = e_amount.to_d
      self.e_duration = e_duration.to_i
      self.p_amount   = p_amount.to_d
      self.p_ps       = ps.to_d / 100.00
      self.p_ir       = ir.to_d / 100.00
      self._cache     = Hash.new
    end
  end
end
