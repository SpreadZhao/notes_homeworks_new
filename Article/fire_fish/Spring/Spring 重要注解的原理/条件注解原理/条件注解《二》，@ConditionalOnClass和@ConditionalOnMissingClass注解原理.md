
@ConditionalOnClass和@ConditionalOnMissingClass注解2个注解是用同一个类完成功能的。

这个类是：OnClassCondition，至于如何执行到这个类的getMatchOutcome方法在【条件注解《一》，@Conditional的通用逻辑.md】
已经说明了，本文直接看OnClassCondition的原理。

### OnClassCondition的匹配方法matches
```java
class OnClassCondition extends SpringBootCondition {

	@Override
	public ConditionOutcome getMatchOutcome(ConditionContext context,
	                                        AnnotatedTypeMetadata metadata) {

		StringBuffer matchMessage = new StringBuffer();

		// 1. 有没有@ConditionalOnClass注解
		MultiValueMap<String, Object> onClasses = getAttributes(metadata,
				ConditionalOnClass.class);
		if (onClasses != null) {
			// 2. 既然是判断是否存在，那就用缺失的规则，则把缺失的类记录下来，如果存在缺失那么就不匹配了
			List<String> missing = getMatchingClasses(onClasses, MatchType.MISSING,
					context);
			if (!missing.isEmpty()) {
				return ConditionOutcome
						.noMatch("required @ConditionalOnClass classes not found: "
								+ StringUtils.collectionToCommaDelimitedString(missing));
			}
			matchMessage.append("@ConditionalOnClass classes found: "
					+ StringUtils.collectionToCommaDelimitedString(getMatchingClasses(
					onClasses, MatchType.PRESENT, context)));
		}

		// 3. 有没有@ConditionalOnMissingClass注解
		MultiValueMap<String, Object> onMissingClasses = getAttributes(metadata,
				ConditionalOnMissingClass.class);
		if (onMissingClasses != null) {
			// 4. 既然是判断是否缺失，那就用存在的规则，则把存在的类记录下来，如果存在那么就不匹配了
			List<String> present = getMatchingClasses(onMissingClasses,
					MatchType.PRESENT, context);
			if (!present.isEmpty()) {
				return ConditionOutcome
						.noMatch("required @ConditionalOnMissing classes found: "
								+ StringUtils.collectionToCommaDelimitedString(present));
			}
			matchMessage.append(matchMessage.length() == 0 ? "" : " ");
			matchMessage.append("@ConditionalOnMissing classes not found: "
					+ StringUtils.collectionToCommaDelimitedString(getMatchingClasses(
					onMissingClasses, MatchType.MISSING, context)));
		}

		// 5. 返回匹配结果
		return ConditionOutcome.match(matchMessage.toString());
	}
}
```